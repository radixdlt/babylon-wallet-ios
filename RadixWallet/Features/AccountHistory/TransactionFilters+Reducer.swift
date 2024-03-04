import ComposableArchitecture

// MARK: - TransactionFilters
public struct TransactionFilters: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let filters: [FilterSection]
		public var activeFilters: ActiveFilters

		init(assets: [OnLedgerEntity.Resource], activeFilters: ActiveFilters = .init()) {
			let transferType = FilterSection(
				title: "", // FIXME: Strings
				filters: Filter.TransferType.allCases.map(Filter.transferType)
			)
			let fungibles = FilterSection(
				title: "Tokens", // FIXME: Strings
				filters: Filter.TransferType.allCases.map(Filter.transferType)
			)
			let nonFungibles = FilterSection(
				title: "NFTs", // FIXME: Strings
				filters: Filter.TransferType.allCases.map(Filter.transferType)
			)

			let assetFilters = assets.map(Filter.asset)
			let transaxctionTypeFilters = Filter.TransactionType.allCases.map(Filter.transactionType)

			self.filters = [.init(title: "ddd", filters: tra)]
			self.activeFilters = activeFilters
		}

		public struct FilterSection: Hashable, Sendable {
			let title: String
			let filters: [Filter]
		}

		public enum Filter: Hashable, Sendable {
			case transferType(TransferType)
			case asset(OnLedgerEntity.Resource)
			case transactionType(TransactionType)

			public enum TransferType: CaseIterable, Sendable {
				case withdrawal
				case deposit
			}

			public typealias TransactionType = GatewayAPI.ManifestClass
		}

		public struct ActiveFilters: Hashable, Sendable {
			var transferType: Filter.TransferType? = nil
			var asset: ResourceAddress? = nil
			var transactionType: GatewayAPI.ManifestClass? = nil
		}
	}
}

extension TransactionFilters.State {
	func isActive(_ filter: Filter) -> Bool {
		switch filter {
		case let .transferType(type):
			activeFilters.transferType == type
		case let .asset(asset):
			activeFilters.asset == asset.resourceAddress
		case let .transactionType(type):
			activeFilters.transactionType == type
		}
	}

	mutating func setActive(_ active: Bool, filter: Filter) {
		switch filter {
		case let .transferType(type):
			toggle(\.transferType, on: active, value: type)
		case let .asset(asset):
			toggle(\.asset, on: active, value: asset.resourceAddress)
		case let .transactionType(type):
			toggle(\.transactionType, on: active, value: type)
		}
	}

	private mutating func toggle<V: Equatable>(_ keyPath: WritableKeyPath<ActiveFilters, V?>, on: Bool, value: V) {
		let isCurrentlyActive = activeFilters[keyPath: keyPath] == value
		if on, !isCurrentlyActive {
			activeFilters[keyPath: keyPath] = value
		} else if !on, isCurrentlyActive {
			activeFilters[keyPath: keyPath] = nil
		} else {
			assertionFailure("Tried to turn off inactive filter, or vice versa")
		}
	}

	// OR:

	mutating func toggle(_ filter: Filter) {
		switch filter {
		case let .transferType(type):
			toggle(\.transferType, value: type)
		case let .asset(asset):
			toggle(\.asset, value: asset.resourceAddress)
		case let .transactionType(type):
			toggle(\.transactionType, value: type)
		}
	}

	private mutating func toggle<V: Equatable>(_ keyPath: WritableKeyPath<ActiveFilters, V?>, value: V) {
		if activeFilters[keyPath: keyPath] == value {
			activeFilters[keyPath: keyPath] = nil
		} else {
			activeFilters[keyPath: keyPath] = value
		}
	}
}
