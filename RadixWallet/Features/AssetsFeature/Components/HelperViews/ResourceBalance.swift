// MARK: - ResourceBalance
public struct ResourceBalance: Sendable, Hashable {
	public let resource: OnLedgerEntity.Resource
	public let details: Details

	public enum Details: Sendable, Hashable {
		case fungible
		case nonFungibleToken(NonFungibleToken)
		case lsu(LSU)
		case poolUnit(PoolUnit)
	}

	public typealias NonFungibleToken = OnLedgerEntity.NonFungibleToken

	public struct LSU: Sendable, Hashable {
		public let address: ResourceAddress
		public let icon: URL?
		public let title: String?
//		public let amount: Amount?
		public let worth: RETDecimal
		public var validatorName: String? = nil
	}

	public typealias PoolUnit = OnLedgerEntity.ResourcePool

	// Helper types

	public struct Amount: Sendable, Hashable {
		public let amount: RETDecimal
		public let guaranteed: RETDecimal?

		init(_ amount: RETDecimal, guaranteed: RETDecimal? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}
	}
}

// MARK: - ResourceBalanceViewState
public enum ResourceBalanceViewState: Sendable, Hashable {
	case fungible(Fungible)
	case nonFungible(NonFungible)
	case lsu(LSU)
	case poolUnit(PoolUnit)

	public struct Fungible: Sendable, Hashable {
		public let address: ResourceAddress
		public let icon: Thumbnail.FungibleContent
		public let title: String?
		public let amount: ResourceBalance.Amount?

		init(address: ResourceAddress, icon: Thumbnail.FungibleContent, title: String?, amount: ResourceBalance.Amount? = nil) {
			self.address = address
			self.icon = icon
			self.title = title
			self.amount = amount
		}
	}

	public struct NonFungible: Sendable, Hashable {
		public let id: NonFungibleGlobalId
		public let resourceImage: URL?
		public let resourceName: String?
		public let nonFungibleName: String?
	}

	public struct LSU: Sendable, Hashable {
		public let address: ResourceAddress
		public let icon: URL?
		public let title: String?
		public let amount: ResourceBalance.Amount?
		public let worth: RETDecimal
		public var validatorName: String? = nil
	}

	public struct PoolUnit: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress { resourcePoolAddress }
		public let resourcePoolAddress: ResourcePoolAddress
		public let poolUnitAddress: ResourceAddress
		public let poolIcon: URL?
		public let poolName: String?
		public let amount: ResourceBalance.Amount?
		public var dAppName: Loadable<String?>
		public var resources: Loadable<[ResourceBalanceViewState.Fungible]>
	}
}
