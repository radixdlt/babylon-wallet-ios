import FeaturePrelude

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: Profile.Network.Persona.ID { persona.id }
		public let persona: Profile.Network.Persona

		public init(persona: Profile.Network.Persona) {
			self.persona = persona
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case editButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case edit
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .editButtonTapped:
			return .send(.delegate(.edit))
		}
	}
}
