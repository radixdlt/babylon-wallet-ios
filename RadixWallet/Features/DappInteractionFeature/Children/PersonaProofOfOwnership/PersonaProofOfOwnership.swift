// MARK: - PersonaProofOfOwnership
@Reducer
struct PersonaProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let identityAddress: IdentityAddress
		let dappMetadata: DappMetadata
		var signature: SignProofOfOwnership.State

		var persona: Persona?

		init(
			identityAddress: IdentityAddress,
			dappMetadata: DappMetadata,
			challenge: DappToWalletInteractionAuthChallengeNonce
		) {
			self.identityAddress = identityAddress
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
		case setPersona(Persona)
	}

	enum DelegateAction: Sendable, Equatable {
		case provenOwnership(Persona, SignedAuthChallenge)
		case failedToGetPersona
		case failedToSign
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case signature(SignProofOfOwnership.Action)
	}

	@Dependency(\.personasClient) var personasClient

	var body: some ReducerOf<Self> {
		Scope(state: \.signature, action: \.child.signature) {
			SignProofOfOwnership()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadPersonaEffect(state: state)
		case .continueButtonTapped:
			gatherSignaturePayloadsEffect(state: state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setPersona(persona):
			state.persona = persona
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .signature(.delegate(action)):
			switch action {
			case let .signedChallenge(signedAuthChallenge):
				guard let persona = state.persona else {
					return .none
				}

				return .send(.delegate(.provenOwnership(persona, signedAuthChallenge)))

			case .failedToSign:
				return .send(.delegate(.failedToSign))
			}

		default:
			return .none
		}
	}

	private func loadPersonaEffect(state: State) -> Effect<Action> {
		.run { send in
			let persona = try await personasClient.getPersona(id: state.identityAddress)
			await send(.internal(.setPersona(persona)))
		} catch: { error, send in
			loggerGlobal.error("Failed to get Persona to proove its ownership, \(error)")
			await send(.delegate(.failedToGetPersona))
		}
	}

	private func gatherSignaturePayloadsEffect(state: State) -> Effect<Action> {
		guard
			let persona = state.persona,
			let signers = NonEmpty<Set<AccountOrPersona>>(rawValue: .init([AccountOrPersona.persona(persona)]))
		else {
			return .send(.delegate(.failedToGetPersona))
		}

		return .send(.child(.signature(.internal(.handle(signers: signers)))))
	}
}
