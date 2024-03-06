import ComposableArchitecture

// MARK: - TransactionFilters
public struct TransactionFilters: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public private(set) var filters: Filters

		public struct Filters: Hashable, Sendable {
			var transferTypes: IdentifiedArrayOf<Filter>
			var fungibles: IdentifiedArrayOf<Filter>
			var nonFungibles: IdentifiedArrayOf<Filter>
			var transactionTypes: IdentifiedArrayOf<Filter>

			var all: IdentifiedArrayOf<Filter> {
				transferTypes + fungibles + nonFungibles + transactionTypes
			}
		}

		public struct Filter: Hashable, Sendable, Identifiable {
			public let id: FilterType
			let icon: ImageAsset?
			let label: String
			var isActive: Bool

			public func hash(into hasher: inout Hasher) {
				hasher.combine(id)
			}
		}

		public enum FilterType: Hashable, Sendable {
			case transferType(TransferType)
			case asset(ResourceAddress)
			case transactionType(TransactionType)
		}

		public enum TransferType: CaseIterable, Sendable {
			case withdrawal
			case deposit
		}

		public typealias TransactionType = GatewayAPI.ManifestClass
	}

	public enum ViewAction: Equatable, Sendable {
		case addTapped(State.FilterType)
		case removeTapped(State.FilterType)
	}

	public enum DelegateAction: Equatable, Sendable {
		case updateActiveFilters(IdentifiedArrayOf<State.Filter>)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .addTapped(filter):
			state.setActive(true, filter: filter)
			return activeFiltersChanged(state: state)

		case let .removeTapped(filter):
			state.setActive(false, filter: filter)
			return activeFiltersChanged(state: state)
		}
	}

	private func activeFiltersChanged(state: State) -> Effect<Action> {
		let activeFilters = state.filters.all.filter(\.isActive)
		return .send(.delegate(.updateActiveFilters(activeFilters)))
	}
}

extension TransactionFilters.State {
	init(assets: [OnLedgerEntity.Resource], activeFilters: [FilterType]) {
		let transferTypes = TransferType.allCases.map { Filter($0, isActive: activeFilters.contains(.transferType($0))) }
		let fungibles = assets.filter { $0.fungibility == .fungible }.compactMap { Filter($0, isActive: activeFilters.contains(.asset($0.id))) }
		let nonFungibles = assets.filter { $0.fungibility == .nonFungible }.compactMap { Filter($0, isActive: activeFilters.contains(.asset($0.id))) }
		let transactionTypes = TransactionType.allCases.map { Filter($0, isActive: activeFilters.contains(.transactionType($0))) }

		self.filters = .init(transferTypes: transferTypes, fungibles: fungibles, nonFungibles: nonFungibles, transactionTypes: transactionTypes)
	}

	mutating func setActive(_ active: Bool, filter: TransactionFilters.State.FilterType) {
		switch filter {
		case .transferType:
			filters.transferTypes.setActive(filter, active: active)
		case .asset:
			filters.fungibles.setActive(filter, active: active)
			filters.nonFungibles.setActive(filter, active: active)
		case .transactionType:
			filters.transactionTypes.setActive(filter, active: active)
		}
	}
}

extension TransactionFilters.State.Filters {
	typealias Filter = TransactionFilters.State.Filter
	init(transferTypes: [Filter], fungibles: [Filter], nonFungibles: [Filter], transactionTypes: [Filter]) {
		self.transferTypes = transferTypes.asIdentifiable()
		self.fungibles = fungibles.asIdentifiable()
		self.nonFungibles = nonFungibles.asIdentifiable()
		self.transactionTypes = transactionTypes.asIdentifiable()
	}
}

extension TransactionFilters.State.Filter {
	init(_ transferType: TransactionFilters.State.TransferType, isActive: Bool) {
		self.init(
			id: .transferType(transferType),
			icon: Self.icon(for: transferType),
			label: Self.label(for: transferType),
			isActive: isActive
		)
	}

	private static func icon(for transferType: TransactionFilters.State.TransferType) -> ImageAsset {
		switch transferType {
		case .withdrawal:
			AssetResource.transactionHistoryWithdrawal
		case .deposit:
			AssetResource.transactionHistoryDeposit
		}
	}

	// FIXME: Strings
	private static func label(for transferType: TransactionFilters.State.TransferType) -> String {
		switch transferType {
		case .withdrawal:
			"Withdrawals"
		case .deposit:
			"Deposits"
		}
	}

	init?(_ asset: OnLedgerEntity.Resource, isActive: Bool) {
		guard let symbol = asset.metadata.symbol else { return nil }
		self.init(id: .asset(asset.resourceAddress), icon: nil, label: symbol, isActive: isActive)
	}

	init(_ transactionType: TransactionFilters.State.TransactionType, isActive: Bool) {
		self.init(
			id: .transactionType(transactionType),
			icon: nil,
			label: Self.label(for: transactionType),
			isActive: isActive
		)
	}

	// FIXME: Strings
	private static func label(for transactionType: TransactionFilters.State.TransactionType) -> String {
		switch transactionType {
		case .general: "General"
		case .transfer: "Transfers"
		case .poolContribution: "Contribute"
		case .poolRedemption: "Redeem"
		case .validatorStake: "Stake"
		case .validatorUnstake: "Unstake"
		case .validatorClaim: "Claim"
		case .accountDepositSettingsUpdate: "Third-party Deposit Settings"
		}
	}
}

extension IdentifiedArrayOf<TransactionFilters.State.Filter> {
	/// Sets the `isActive` flag of the filter with the id of `filterType` to `active`, and all others to `false`
	mutating func setActive(_ filterType: TransactionFilters.State.FilterType, active: Bool) {
		for id in ids {
			self[id: id]?.isActive = id == filterType ? active : false
		}
	}
}
