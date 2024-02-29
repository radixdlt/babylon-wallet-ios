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
		public let fiatWorth: FiatWorth?
		public let guaranteed: RETDecimal?

		init(_ amount: RETDecimal, fiatWorth: FiatWorth? = nil, guaranteed: RETDecimal? = nil) {
			self.amount = amount
			self.fiatWorth = fiatWorth
			self.guaranteed = guaranteed
		}

		init(_ amount: ResourceAmount) {
			self.amount = amount.nominalAmount
			self.fiatWorth = amount.fiatWorth
			self.guaranteed = nil
		}
	}
}

extension ResourceBalance {
	var viewState: ViewState {
		switch details {
		case .fungible:
//			return .fungible(
//				.init(
//					address: <#T##ResourceAddress#>,
//					icon: <#T##Thumbnail.FungibleContent#>,
//					title: <#T##String?#>,
//					amount: <#T##Amount?#>
//				)
//			)
			fatalError()
		case let .nonFungibleToken(details):
			fatalError()
		case let .lsu(details):
			fatalError()
		case let .poolUnit(details):
			fatalError()
		}
	}
}

// MARK: ResourceBalance.ViewState
extension ResourceBalance {
	// MARK: - ViewState
	public enum ViewState: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case lsu(LSU)
		case poolUnit(PoolUnit)

		public struct Fungible: Sendable, Hashable {
			public let address: ResourceAddress
			public let icon: Thumbnail.FungibleContent
			public let title: String?
			public let amount: ResourceBalance.Amount?
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
			public let worth: ResourceAmount
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
			public var resources: Loadable<[Fungible]>
		}
	}
}
