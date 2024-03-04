import ComposableArchitecture

// MARK: - TransactionFilters
public struct TransactionFilters: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let filters: Filters
		public var activeFilters: ActiveFilters = .init()

		init(fungible: [OnLedgerEntity.Resource], nonFungible: [OnLedgerEntity.Resource]) {
			self.filters = .init(fungibleAssets: fungible, nonFungibleAssets: nonFungible)
		}
	}

	public struct Filters: Hashable, Sendable {
		let transferType: [TransferType] = TransferType.allCases
		let fungibleAssets: [OnLedgerEntity.Resource]
		let nonFungibleAssets: [OnLedgerEntity.Resource]
		let transactionType: [GatewayAPI.ManifestClass] = GatewayAPI.ManifestClass.allCases
		let submittedBy: [Submitter] = Submitter.allCases

		public enum TransferType: CaseIterable, Sendable {
			case withdrawal
			case deposit
		}

		public enum Submitter: CaseIterable, Sendable {
			case me
			case thirdParty
		}
	}

	public enum Filter: Hashable, Sendable {
		case transferType(Filters.TransferType)
		case asset(ResourceAddress)
		case transactionType(GatewayAPI.ManifestClass)
		case submittedBy(Filters.Submitter)
	}

	public struct ActiveFilters: Hashable, Sendable {
		var transferType: Filters.TransferType? = nil
		var asset: ResourceAddress? = nil
		var transactionType: GatewayAPI.ManifestClass? = nil
		var submittedBy: Filters.Submitter? = nil
	}
}

/*
 list of all filters
 some are active
 toggle filter x
 apply active filters

 */
