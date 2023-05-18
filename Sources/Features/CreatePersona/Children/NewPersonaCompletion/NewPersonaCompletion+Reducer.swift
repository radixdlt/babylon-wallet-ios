import FeaturePrelude

public struct NewPersonaCompletion: Sendable, FeatureReducer {
	public struct State: Sendable & Hashable {
		public let persona: Profile.Network.Persona
		public let isFirstOnNetwork: Bool
		public let navigationButtonCTA: CreateEntityNavigationButtonCTA

		public init(
			persona: Profile.Network.Persona,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreateEntityNavigationButtonCTA
		) {
			self.persona = persona
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		public init(
			persona: Profile.Network.Persona,
			config: CreateEntityConfig
		) {
			self.init(
				persona: persona,
				isFirstOnNetwork: config.isFirstEntity,
				navigationButtonCTA: config.navigationButtonCTA
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case goToDestination
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .goToDestination:
			return .send(.delegate(.completed))
		}
	}
}
