import FeaturePrelude

// MARK: - AccountCompletion.State
public extension AccountCompletion {
	struct State: CreateEntityCompletionStateProtocol {
		public typealias Entity = OnNetwork.Account
		public typealias Destination = CreateAccountCompletionDestination
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

// MARK: - AccountCompletion.State.Origin
public extension AccountCompletion.State {
	var entityAddress: Entity.EntityAddress {
		entity.address
	}

	var displayName: String {
		if let displayName = entity.displayName {
			return displayName
		}
		return "Unnamed " + (entity.kind == .account ? "account" : "persona")
	}

	var index: Entity.Index {
		entity.index
	}
}

#if DEBUG
public extension AccountCompletion.State where Entity == OnNetwork.Account, Destination == CreateAccountCompletionDestination {
	static let previewValue: Self = .init(
		entity: OnNetwork.Account.previewValue0,
		isFirstOnNetwork: true,
		destination: .home
	)
}
#endif
