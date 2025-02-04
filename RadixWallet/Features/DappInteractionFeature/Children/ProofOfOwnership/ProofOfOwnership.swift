// MARK: - ProofOfOwnership
@Reducer
struct ProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let kind: Kind
		let dappMetadata: DappMetadata
		let challenge: DappToWalletInteractionAuthChallengeNonce

		var persona: Persona?
		var accounts: Accounts = []

		init(
			identityAddress: IdentityAddress,
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.kind = .persona(identityAddress)
			self.dappMetadata = dappMetadata
			self.challenge = challenge
		}

		init(
			accountAddresses: [AccountAddress],
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.kind = .accounts(accountAddresses)
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
		case setPersona(Persona)
		case setAccounts(Accounts)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenPersonaOwnership(IdentityAddress, SignedAuthIntent)
		case provenAccountsOwnership([AccountAddress], SignedAuthIntent)
		case failedToGetEntities
		case failedToSign
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.accountsClient) var accountsClient

	var body: some ReducerOf<Self> {
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
			triggerSignaturesEffect(state: state)
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

	func triggerSignaturesEffect(state: State) -> Effect<Action> {
		guard let metadata = state.dappMetadata.requestMetadata else {
			assertionFailure("Unable to sign Proof of Ownership without the request metadata")
			return .none
		}
		switch state.kind {
		case let .persona(identityAddress):
			return .run { [challenge = state.challenge] send in
				let signedAuthIntent = try await SargonOS.shared.signAuthPersona(identityAddress: identityAddress, challengeNonce: challenge, metadata: metadata)
				await send(.delegate(.provenPersonaOwnership(identityAddress, signedAuthIntent)))
			} catch: { _, send in
				await send(.delegate(.failedToSign))
			}

		case let .accounts(accountAddresses):
			return .run { [challenge = state.challenge] send in
				let signedAuthIntent = try await SargonOS.shared.signAuthAccounts(accountAddresses: accountAddresses, challengeNonce: challenge, metadata: metadata)
				await send(.delegate(.provenAccountsOwnership(accountAddresses, signedAuthIntent)))
			} catch: { _, send in
				await send(.delegate(.failedToSign))
			}
		}
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
