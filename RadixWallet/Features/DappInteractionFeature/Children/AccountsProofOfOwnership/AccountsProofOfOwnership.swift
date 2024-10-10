// MARK: - AccountsProofOfOwnership
@Reducer
struct AccountsProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let accountAddresses: [AccountAddress]
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

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
			self.challenge = challenge
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setAccounts(Accounts)
		case performSignature(SigningFactors, AuthenticationDataToSignForChallengeResponse)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership([AccountAuthProof], SignedAuthChallenge)
		case failedToGetAccounts
		case failedToSign
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case signing(Signing.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case signing(Signing.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.signing, action: \.signing) {
				Signing()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

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
		case let .performSignature(signingFactors, authToSignResponse):
			state.destination = .signing(.init(
				factorsLeftToSignWith: signingFactors,
				signingPurposeWithPayload: .signAuth(authToSignResponse)
			))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .signing(.delegate(signingAction)):
			switch signingAction {
			case .cancelSigning:
				// If the user cancels the signing flow, we just dismiss the `Signing` view and wllow them
				// to retry by tapping Continue again.
				state.destination = nil
				return .none

			case let .finishedSigning(.signAuth(signedAuthChallenge)):
				state.destination = nil

				var accountsLeftToVerifyDidSign: Set<Account.ID> = Set(state.accounts.map(\.id))

				let accountAuthProofs: [AccountAuthProof] = signedAuthChallenge.entitySignatures.compactMap { signature in
					guard let account = try? signature.signerEntity.asAccount() else {
						return nil
					}
					accountsLeftToVerifyDidSign.remove(account.id)
					let proof = WalletToDappInteractionAuthProof(entitySignature: signature)
					return .init(account: account, proof: proof)
				}

				guard accountsLeftToVerifyDidSign.isEmpty else {
					loggerGlobal.error("Failed to sign with all accounts")
					return .send(.delegate(.failedToSign))
				}

				return .send(.delegate(.provenOwnership(accountAuthProofs, signedAuthChallenge)))

			case .failedToSign:
				state.destination = nil
				loggerGlobal.error("Failed to sign proof of ownership")
				return .send(.delegate(.failedToSign))

			case .finishedSigning(.signTransaction):
				state.destination = nil
				assertionFailure("Signed a transaction while expecting auth")
				loggerGlobal.error("Signed a transaction while expecting auth")
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
		guard let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: Set(state.accounts.map { AccountOrPersona.account($0) })) else {
			return .send(.delegate(.failedToGetAccounts))
		}

		let createAuthPayloadRequest = AuthenticationDataToSignForChallengeRequest(
			challenge: state.challenge,
			origin: state.dappMetadata.origin,
			dAppDefinitionAddress: state.dappMetadata.dAppDefinitionAddress
		)

		return .run { send in
			let signingFactors = try await factorSourcesClient.getSigningFactors(.init(
				networkID: accountsClient.getCurrentNetworkID(),
				signers: signers,
				signingPurpose: .signAuth
			))
			let authToSignResponse = try rolaClient.authenticationDataToSignForChallenge(createAuthPayloadRequest)
			await send(.internal(.performSignature(signingFactors, authToSignResponse)))
		} catch: { _, send in
			loggerGlobal.error("Failed to gather signature payloads")
			await send(.delegate(.failedToSign))
		}
	}
}

// MARK: - AccountAuthProof
struct AccountAuthProof: Sendable, Hashable {
	let account: Account
	let proof: WalletToDappInteractionAuthProof
}
