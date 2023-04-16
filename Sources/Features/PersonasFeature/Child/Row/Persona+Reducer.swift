import FeaturePrelude

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Profile.Network.Persona.ID
		public let thumbnail: URL?
		public let displayName: String

		public init(persona: Profile.Network.AuthorizedPersonaDetailed) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue
			)
		}

		public init(persona: Profile.Network.Persona) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue
			)
		}

		public init(id: Profile.Network.Persona.ID, thumbnail: URL?, displayName: String) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .tapped:
			return .send(.delegate(.openDetails))
		}
	}
}
