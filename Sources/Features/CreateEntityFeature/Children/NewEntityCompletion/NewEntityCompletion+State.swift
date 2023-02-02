import FeaturePrelude

// MARK: - NewEntityCompletion.State
public extension NewEntityCompletion {
	struct State: Sendable & Equatable {
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

public extension NewEntityCompletion.State {
	init(entity: Entity, config: CreateEntityConfig) {
		self.init(
			entity: entity,
			isFirstOnNetwork: config.isFirstEntity,
			navigationButtonCTA: config.navigationButtonCTA
		)
	}
}

// MARK: - NewEntityCompletion.State.Origin
public extension NewEntityCompletion.State {
	var entityAddress: Entity.EntityAddress {
		entity.address
	}

	var displayName: String {
		if let displayName = entity.displayName {
			return displayName
		}
		return "Unnamed " + (entity.kind == .account ? "account" : "persona")
	}

	var index: Int {
		entity.index
	}
}

//
// #if DEBUG
// public extension NewEntityCompletion.State where Entity == OnNetwork.Account, Destination == CreateAccountCompletionDestination {
//	static let previewValue: Self = .init(
//		entity: OnNetwork.Account.previewValue0,
//		isFirstOnNetwork: true,
//		destination: .home
//	)
// }
// #endif
