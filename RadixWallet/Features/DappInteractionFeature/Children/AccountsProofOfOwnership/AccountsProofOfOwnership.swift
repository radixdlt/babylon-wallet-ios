// MARK: - AccountsProofOfOwnership
@Reducer
struct AccountsProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let accountAddresses: [AccountAddress]
		let dappMetadata: DappMetadata
		var signature: SignProofOfOwnership.State

		var accounts: Accounts = []

		@Presents
		var destination: Destination.State?

		init(
			accountAddresses: [AccountAddress],
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.accountAddresses = accountAddresses
			self.dappMetadata = dappMetadata
			self.signature = .init(dappMetadata: dappMetadata, challenge: challenge)
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setAccounts(Accounts)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership([AccountAuthProof], SignedAuthChallenge)
		case failedToGetAccounts
		case failedToSign
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case signature(SignProofOfOwnership.Action)
	}

	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerOf<Self> {
		Scope(state: \.signature, action: \.child.signature) {
			SignProofOfOwnership()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadAccountsEffect(state: state)
		case .continueButtonTapped:
			gatherSignaturePayloadsEffect(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setAccounts(accounts):
			state.accounts = accounts
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .signature(.delegate(action)):
			switch action {
			case let .signedChallenge(signedAuthChallenge):
				let accountAuthProofs: [AccountAuthProof] = signedAuthChallenge.entitySignatures.compactMap { signature in
					guard let account = try? signature.signerEntity.asAccount() else {
						return nil
					}
					let proof = WalletToDappInteractionAuthProof(entitySignature: signature)
					return .init(account: account, proof: proof)
				}

				guard Set(state.accounts.map(\.id)) == Set(accountAuthProofs.map(\.account.id)) else {
					loggerGlobal.error("Failed to sign with all accounts")
					return .send(.delegate(.failedToSign))
				}

				return .send(.delegate(.provenOwnership(accountAuthProofs, signedAuthChallenge)))

			case .failedToSign:
				return .send(.delegate(.failedToSign))
			}

		default:
			return .none
		}
	}

	private func loadAccountsEffect(state: State) -> Effect<Action> {
		.run { send in
			let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
			let accounts = allAccounts.filter {
				state.accountAddresses.contains($0.address)
			}
			if accounts.count == state.accountAddresses.count {
				await send(.internal(.setAccounts(accounts)))
			} else {
				await send(.delegate(.failedToGetAccounts))
			}

		} catch: { error, send in
			loggerGlobal.error("Failed to fetch Accounts to prove its ownership, \(error)")
			await send(.delegate(.failedToGetAccounts))
		}
	}

	private func gatherSignaturePayloadsEffect(state: State) -> Effect<Action> {
		guard
			let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: Set(state.accounts.map { AccountOrPersona.account($0) }))
		else {
			return .send(.delegate(.failedToGetAccounts))
		}

		return .send(.child(.signature(.internal(.handle(signers: signers)))))
	}
}

// MARK: - AccountAuthProof
struct AccountAuthProof: Sendable, Hashable {
	let account: Account
	let proof: WalletToDappInteractionAuthProof
}
