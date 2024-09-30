// MARK: - PersonaProofOfOwnership
@Reducer
struct PersonaProofOfOwnership: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let identityAddress: IdentityAddress
		let dappMetadata: DappMetadata

		var persona: Persona?

		init(
			identityAddress: IdentityAddress,
			dappMetadata: DappMetadata
		) {
			self.identityAddress = identityAddress
			self.dappMetadata = dappMetadata
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

	@Dependency(\.personasClient) var personasClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			loadPersonaEffect(state: state)
		case .continueButtonTapped:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setPersona(persona):
			state.persona = persona
			return .none
		}
	}

	private func loadPersonaEffect(state: State) -> Effect<Action> {
		.run { send in
			let persona = try await personasClient.getPersona(id: state.identityAddress)
			await send(.internal(.setPersona(persona)))
		} catch: { _, _ in
			// TODO: Handle persona not found
		}
	}
}
