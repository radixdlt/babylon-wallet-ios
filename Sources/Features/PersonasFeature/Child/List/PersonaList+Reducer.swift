import FeaturePrelude

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var showCreateButton: Bool
		public var personas: IdentifiedArrayOf<Persona.State>

		public init(
			showCreateButton: Bool,
			personas: IdentifiedArrayOf<Persona.State> = []
		) {
			self.showCreateButton = showCreateButton
			self.personas = personas
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case createNewPersonaButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case persona(id: Profile.Network.Persona.ID, action: Persona.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
		case openDetails(Profile.Network.Persona)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.personas, action: /Action.child .. ChildAction.persona) {
				Persona()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .createNewPersonaButtonTapped:
			return .send(.delegate(.createNewPersona))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .persona(id: _, action: .delegate(.openDetails(let persona))):
			return .send(.delegate(.openDetails(persona)))

		case .persona:
			return .none
		}
	}
}
