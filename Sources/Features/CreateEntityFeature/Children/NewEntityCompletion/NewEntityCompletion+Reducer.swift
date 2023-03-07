import FeaturePrelude

// MARK: - NewEntityCompletion
public struct NewEntityCompletion<Entity: EntityProtocol & Sendable & Hashable>: Sendable, FeatureReducer {
	public struct State: Sendable & Hashable {
		public let entity: Entity
		public let isFirstOnNetwork: Bool
		public let navigationButtonCTA: CreateEntityNavigationButtonCTA

		public init(
			entity: Entity,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreateEntityNavigationButtonCTA
		) {
			self.entity = entity
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		public init(
			entity: Entity,
			config: CreateEntityConfig
		) {
			self.init(
				entity: entity,
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
