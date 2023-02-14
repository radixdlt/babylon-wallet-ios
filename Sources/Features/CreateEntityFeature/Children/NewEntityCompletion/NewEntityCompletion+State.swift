import FeaturePrelude

// MARK: - NewEntityCompletion.State
extension NewEntityCompletion {
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
	}
}

extension NewEntityCompletion.State {
	public init(entity: Entity, config: CreateEntityConfig) {
		self.init(
			entity: entity,
			isFirstOnNetwork: config.isFirstEntity,
			navigationButtonCTA: config.navigationButtonCTA
		)
	}
}

// MARK: - NewEntityCompletion.State.Origin
extension NewEntityCompletion.State {
	public var entityAddress: Entity.EntityAddress {
		entity.address
	}

	public var displayName: String {
		entity.displayName.rawValue
	}

	public var index: Int {
		entity.index
	}
}
