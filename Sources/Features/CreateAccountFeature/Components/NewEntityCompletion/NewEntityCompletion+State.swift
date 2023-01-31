import FeaturePrelude

// MARK: - NewEntityCompletion.State
public extension NewEntityCompletion {
	struct State: CreateEntityCompletionStateProtocol {
		public let entity: Entity
		public let isFirstOnNetwork: Bool
		public let destination: Destination

		public init(
			entity: Entity,
			isFirstOnNetwork: Bool,
			destination: Destination
		) {
			self.entity = entity
			self.isFirstOnNetwork = isFirstOnNetwork
			self.destination = destination
		}
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
