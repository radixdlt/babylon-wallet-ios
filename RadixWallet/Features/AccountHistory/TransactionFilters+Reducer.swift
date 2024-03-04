import ComposableArchitecture

// MARK: - TransactionFilters
public struct TransactionFilters: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let filters: Filters
		var activeFilters: ActiveFilters

		public enum TransferType: CaseIterable, Sendable {
			case withdrawal
			case deposit
		}

		public typealias TransactionType = GatewayAPI.ManifestClass

		public struct Filters: Hashable, Sendable {
			let transferTypes: [TransferType]
			let fungibles: [OnLedgerEntity.Resource]
			let nonFungibles: [OnLedgerEntity.Resource]
			let transactionTypes: [TransactionType]
		}

		public struct ActiveFilters: Hashable, Sendable {
			var transferType: TransferType? = nil
			var asset: ResourceAddress? = nil
			var transactionType: TransactionType? = nil
		}

		// This type is used for toggling active filters
		public enum FilterType: Hashable, Sendable {
			case transferType(State.TransferType)
			case asset(ResourceAddress)
			case transactionType(State.TransactionType)
		}

		init(assets: [OnLedgerEntity.Resource], activeFilters: ActiveFilters = .init()) {
			self.filters = .init(
				transferTypes: TransferType.allCases,
				fungibles: assets.filter { $0.fungibility == .fungible },
				nonFungibles: assets.filter { $0.fungibility == .nonFungible },
				transactionTypes: TransactionType.allCases
			)
			self.activeFilters = activeFilters
		}
	}
}

extension TransactionFilters.State {
	func isActive(_ filter: FilterType) -> Bool {
		switch filter {
		case let .transferType(type):
			activeFilters.transferType == type
		case let .asset(asset):
			activeFilters.asset == asset
		case let .transactionType(type):
			activeFilters.transactionType == type
		}
	}

	mutating func setActive(_ active: Bool, filter: FilterType) {
		switch filter {
		case let .transferType(type):
			toggle(\.transferType, on: active, value: type)
		case let .asset(asset):
			toggle(\.asset, on: active, value: asset)
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
}
