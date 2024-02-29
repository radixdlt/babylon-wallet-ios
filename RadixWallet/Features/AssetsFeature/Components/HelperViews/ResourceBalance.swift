// MARK: - ResourceBalance
public struct ResourceBalance: Sendable, Hashable {
	public let resource: OnLedgerEntity.Resource
	public let details: Details

	public enum Details: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case lsu(LSU)
		case poolUnit(PoolUnit)
	}

	public struct Fungible: Sendable, Hashable {
		public let amount: Amount?
	}

	public typealias NonFungible = OnLedgerEntity.NonFungibleToken

	public struct LSU: Sendable, Hashable {
		public let amount: Amount?
		public let validator: OnLedgerEntity.Validator
	}

	public struct PoolUnit: Sendable, Hashable {
		public let amount: Amount?
		public let pool: OnLedgerEntity.ResourcePool
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

extension ResourceBalance {
	var viewState: ViewState {
		switch details {
		case let .fungible(details):
			.fungible(.init(
				address: resource.resourceAddress,
				icon: .token(.other(resource.metadata.iconURL)),
				title: resource.metadata.title,
				amount: details.amount
			))
		case let .nonFungible(details):
			fatalError()
		case let .lsu(details):
			fatalError()
		case let .poolUnit(details):
			fatalError()
		}
	}
}

extension ResourceBalance {
	init(_ transfer: TransactionReview.Transfer) {
		self.resource = transfer.resource

		switch transfer.details {
		case let .fungible(details):
			self.details = .fungible(.init(details))
		case let .nonFungible(details):
			self.details = .nonFungible(details)
		case let .liquidStakeUnit(details):
			fatalError()
		case let .poolUnit(details):
			fatalError()
		case let .stakeClaimNFT(details):
			fatalError()
		}
	}
}

private extension ResourceBalance.Fungible {
	init(_ details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			amount: .init(
				details.amount,
				guaranteed: details.guarantee?.amount
			)
		)
	}
}

// private extension ResourceBalance.NonFungible {
//	init(_ details: TransactionReview.Transfer.Details.NonFungible) {
//		self = details
//	}
// }

extension ResourceBalance.ViewState { // FIXME: GK use full?
	init(transfer: TransactionReview.Transfer) {
		switch transfer.details {
		case let .fungible(details):
			self = .fungible(.init(resource: transfer.resource, details: details))
		case let .nonFungible(details):
			self = .nonFungible(.init(resource: transfer.resource, details: details))
		case let .liquidStakeUnit(details):
			self = .lsu(.init(resource: transfer.resource, details: details))
		case let .poolUnit(details):
			self = .poolUnit(.init(resource: transfer.resource, details: details))
		case let .stakeClaimNFT(details):
			fatalError()
		}
	}
}

private extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.Fungible) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount)
		)
	}
}

private extension ResourceBalance.ViewState.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.NonFungible) {
		self.init(
			id: details.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: details.data?.name
		)
	}
}

private extension ResourceBalance.ViewState.LSU {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.LiquidStakeUnit) {
		self.init(
			address: resource.resourceAddress,
			icon: resource.metadata.iconURL,
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount),
			worth: details.worth,
			validatorName: details.validator.metadata.name
		)
	}
}

private extension ResourceBalance.ViewState.PoolUnit {
	init(resource: OnLedgerEntity.Resource, details: TransactionReview.Transfer.Details.PoolUnit) {
		self.init(
			resourcePoolAddress: details.details.address,
			poolUnitAddress: resource.resourceAddress,
			poolIcon: resource.metadata.iconURL,
			poolName: resource.fungibleResourceName,
			amount: .init(details.details.poolUnitResource.amount, guaranteed: details.guarantee?.amount),
			dAppName: .success(details.details.dAppName),
			resources: .success(.init(resources: details.details))
		)
	}
}

// MARK: - ResourceBalance.ViewState
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
			public var resources: Loadable<[Fungible]>
		}
	}
}
