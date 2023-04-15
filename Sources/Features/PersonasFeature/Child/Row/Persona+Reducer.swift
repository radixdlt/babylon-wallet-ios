import AuthorizedDAppsFeature
import FeaturePrelude

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: Profile.Network.Persona.ID { persona.id }
		public let persona: Profile.Network.Persona
		public let thumbnail: URL?
		public let displayName: String

		public init(persona: Profile.Network.Persona) {
			self.persona = persona
			self.thumbnail = nil
			self.displayName = persona.displayName.rawValue
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails(Profile.Network.Persona)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .tapped:
			return .send(.delegate(.openDetails(state.persona)))
		}
	}
}
