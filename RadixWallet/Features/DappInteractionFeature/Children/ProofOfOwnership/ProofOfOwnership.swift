// MARK: - ProofOfOwnership
@Reducer
struct ProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: Kind
		let dappMetadata: DappMetadata
		var sign: SignProofOfOwnership.State

		var persona: Persona?
		var accounts: Accounts = []

		init(
			identityAddress: IdentityAddress,
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.kind = .persona(identityAddress)
			self.dappMetadata = dappMetadata
			self.sign = .init(dappMetadata: dappMetadata, challenge: challenge)
		}

		init(
			accountAddresses: [AccountAddress],
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.kind = .accounts(accountAddresses)
			self.dappMetadata = dappMetadata
			self.sign = .init(dappMetadata: dappMetadata, challenge: challenge)
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case setPersona(Persona)
		case setAccounts(Accounts)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenPersonaOwnership(Persona, SignedAuthChallenge)
		case provenAccountsOwnership([AccountAuthProof], SignedAuthChallenge)
		case failedToGetEntities
		case failedToSign
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case sign(SignProofOfOwnership.Action)
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerOf<Self> {
		Scope(state: \.sign, action: \.child.sign) {
			SignProofOfOwnership()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			switch state.kind {
			case let .persona(identityAddress):
				loadPersonaEffect(identityAddress: identityAddress)
			case let .accounts(accountAddresses):
				loadAccountsEffect(accountAddresses: accountAddresses)
			}
		case .continueButtonTapped:
			gatherSignaturePayloadsEffect(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setPersona(persona):
			state.persona = persona
			return .none
		case let .setAccounts(accounts):
			state.accounts = accounts
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .sign(.delegate(action)):
			switch action {
			case let .signedChallenge(signedAuthChallenge):
				switch state.kind {
				case .persona:
					guard let persona = state.persona else {
						return .none
					}

					return .send(.delegate(.provenPersonaOwnership(persona, signedAuthChallenge)))

				case .accounts:
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

					return .send(.delegate(.provenAccountsOwnership(accountAuthProofs, signedAuthChallenge)))
				}

			case .failedToSign:
				return .send(.delegate(.failedToSign))
			}

		default:
			return .none
		}
	}
}

private extension ProofOfOwnership {
	func loadPersonaEffect(identityAddress: IdentityAddress) -> Effect<Action> {
		.run { send in
			let persona = try await personasClient.getPersona(id: identityAddress)
			await send(.internal(.setPersona(persona)))
		} catch: { error, send in
			loggerGlobal.error("Failed to get Persona to proove its ownership, \(error)")
			await send(.delegate(.failedToGetEntities))
		}
	}

	func loadAccountsEffect(accountAddresses: [AccountAddress]) -> Effect<Action> {
		.run { send in
			let allAccounts = try await accountsClient.getAccountsOnCurrentNetwork()
			let accounts = allAccounts.filter {
				accountAddresses.contains($0.address)
			}
			if accounts.count == accountAddresses.count {
				await send(.internal(.setAccounts(accounts)))
			} else {
				await send(.delegate(.failedToGetEntities))
			}

		} catch: { error, send in
			loggerGlobal.error("Failed to fetch Accounts to prove its ownership, \(error)")
			await send(.delegate(.failedToGetEntities))
		}
	}

	func gatherSignaturePayloadsEffect(state: State) -> Effect<Action> {
		guard let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: Set(state.signers)) else {
			return .send(.delegate(.failedToGetEntities))
		}
		return .send(.child(.sign(.internal(.handle(signers: signers)))))
	}
}

extension ProofOfOwnership.State {
	enum Kind: Sendable, Hashable {
		case persona(IdentityAddress)
		case accounts([AccountAddress])
	}

	var signers: [AccountOrPersona] {
		switch kind {
		case .persona:
			guard let persona else {
				return []
			}
			return [.persona(persona)]
		case .accounts:
			return accounts.map { .account($0) }
		}
	}
}

// MARK: - AccountAuthProof
struct AccountAuthProof: Sendable, Hashable {
	let account: Account
	let proof: WalletToDappInteractionAuthProof
}
