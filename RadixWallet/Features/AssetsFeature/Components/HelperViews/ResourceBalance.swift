// MARK: - ResourceBalance
public enum ResourceBalance: Sendable, Hashable {
	case fungible(Fungible)
	case nonFungible(NonFungible)
	case lsu(LSU)
	case poolUnit(PoolUnit)

	public struct Fungible: Sendable, Hashable {
		public let address: ResourceAddress
		public let icon: Thumbnail.FungibleContent
		public let title: String?
		public let amount: Amount?

		// FIXME: REMOVE
		init(address: ResourceAddress, tokenIcon: Thumbnail.TokenContent, title: String?, amount: Amount? = nil) {
			self.init(
				address: address,
				icon: .token(tokenIcon),
				title: title,
				amount: amount
			)
		}

		init(address: ResourceAddress, icon: Thumbnail.FungibleContent, title: String?, amount: Amount? = nil) {
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
		public let amount: Amount?
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
		public var resources: Loadable<[ResourceBalance.Fungible]>
	}

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
