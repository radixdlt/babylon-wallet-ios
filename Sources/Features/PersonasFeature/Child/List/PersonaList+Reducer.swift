import EditPersonaFeature
import FeaturePrelude

// MARK: - PersonaList
public struct PersonaList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var personas: IdentifiedArrayOf<Persona.State>

		@PresentationState
		public var editPersona: EditPersona.State? = nil

		public init(
			personas: IdentifiedArrayOf<Persona.State> = []
		) {
			self.personas = personas
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case createNewPersonaButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case editPersona(PresentationAction<EditPersona.Action>)
		case persona(id: Profile.Network.Persona.ID, action: Persona.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewPersona
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$editPersona, action: /Action.child .. ChildAction.editPersona) {
				EditPersona()
			}
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
		case .editPersona:
			return .none

		case .persona(id: let id, action: .delegate(.edit)):
			guard let persona = state.personas[id: id] else {
				return .none
			}

			state.editPersona = .init(
				mode: .dapp(requiredFieldIDs: [.emailAddress]),
				persona: persona.persona
			)

			return .none

		case .persona:
			return .none
		}
	}
}
