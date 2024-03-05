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

			init(transferTypes: [Filter], fungibles: [Filter], nonFungibles: [Filter], transactionTypes: [Filter]) {
				self.transferTypes = transferTypes.asIdentifiable()
				self.fungibles = fungibles.asIdentifiable()
				self.nonFungibles = nonFungibles.asIdentifiable()
				self.transactionTypes = transactionTypes.asIdentifiable()
			}
		}

		public struct Filter: Hashable, Sendable, Identifiable {
			public let id: FilterType
			let icon: ImageAsset?
			let label: String
			var isActive: Bool

			init(id: FilterType, icon: ImageAsset? = nil, label: String, isActive: Bool = false) {
				self.id = id
				self.icon = icon
				self.label = label
				self.isActive = isActive
			}

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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .addTapped(filter):
			state.setActive(true, filter: filter)
			return .none

		case let .removeTapped(filter):
			state.setActive(false, filter: filter)
			return .none
		}
	}
}

extension TransactionFilters.State {
	init(assets: [OnLedgerEntity.Resource], activeFilters: [FilterType] = []) {
		self.filters = Self.filters(for: assets)
	}

	private static func filters(for assets: [OnLedgerEntity.Resource]) -> Filters {
		.init(
			transferTypes: TransferType.allCases.map { .init(id: .transferType($0), icon: icon(for: $0), label: label(for: $0)) },
			fungibles: assets.filter { $0.fungibility == .fungible }.compactMap(assetFilter),
			nonFungibles: assets.filter { $0.fungibility == .nonFungible }.compactMap(assetFilter),
			transactionTypes: TransactionType.allCases.map { .init(id: .transactionType($0), label: label(for: $0)) }
		)
	}

	private static func assetFilter(for asset: OnLedgerEntity.Resource) -> Filter? {
		guard let symbol = asset.metadata.symbol else { return nil }
		return .init(id: .asset(asset.resourceAddress), label: symbol)
	}

	private static func icon(for transferType: TransferType) -> ImageAsset {
		switch transferType {
		case .withdrawal:
			AssetResource.transactionHistoryWithdrawal
		case .deposit:
			AssetResource.transactionHistoryDeposit
		}
	}

	// FIXME: Strings
	private static func label(for transferType: TransferType) -> String {
		switch transferType {
		case .withdrawal:
			"Withdrawals"
		case .deposit:
			"Deposits"
		}
	}

	// FIXME: Strings
	private static func label(for transactionType: TransactionType) -> String {
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

extension TransactionFilters.State.Filter {}

extension IdentifiedArrayOf<TransactionFilters.State.Filter> {
	/// Sets the `isActive` flag of the filter with the id of `filterType` to `active`, and all others to `false`
	mutating func setActive(_ filterType: TransactionFilters.State.FilterType, active: Bool) {
		for id in ids {
			self[id: id]?.isActive = id == filterType ? active : false
		}
	}
}
