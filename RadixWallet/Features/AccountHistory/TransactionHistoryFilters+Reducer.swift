import ComposableArchitecture

// MARK: - TransactionHistoryFilters
public struct TransactionHistoryFilters: Sendable, FeatureReducer {
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

			var showAssetsSection: Bool {
				!(fungibles.isEmpty && nonFungibles.isEmpty)
			}
		}

		public struct Filter: Hashable, Sendable, Identifiable {
			public let id: TransactionFilter
			let icon: ImageResource?
			let label: String
			var isActive: Bool

			public func hash(into hasher: inout Hasher) {
				hasher.combine(id)
			}
		}

		public init(assets: some Collection<OnLedgerEntity.Resource>, activeFilters: [Filter.ID]) {
			let transferTypes = TransactionFilter.TransferType.allCases.map { Filter($0, isActive: activeFilters.contains(.transferType($0))) }
			let fungibles = assets.filter { $0.fungibility == .fungible }.compactMap { Filter($0, isActive: activeFilters.contains(.asset($0.id))) }
			let nonFungibles = assets.filter { $0.fungibility == .nonFungible }.compactMap { Filter($0, isActive: activeFilters.contains(.asset($0.id))) }
			let transactionTypes = TransactionFilter.TransactionType.allCases.map { Filter($0, isActive: activeFilters.contains(.transactionType($0))) }

			self.filters = .init(transferTypes: transferTypes, fungibles: fungibles, nonFungibles: nonFungibles, transactionTypes: transactionTypes)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case filterTapped(TransactionFilter)
		case clearTapped
		case showResultsTapped
		case closeTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case updateActiveFilters(IdentifiedArrayOf<State.Filter>)
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .filterTapped(id):
			guard let filter = state.filters.all[id: id] else {
				assertionFailure("Filter \(id) does not exist")
				return .none
			}
			state.setActive(!filter.isActive, filter: id)
			return activeFiltersChanged(state: state)

		case .clearTapped:
			for id in state.filters.all.ids {
				state.setActive(false, filter: id)
			}
			return .none

		case .showResultsTapped, .closeTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}

	private func activeFiltersChanged(state: State) -> Effect<Action> {
		let activeFilters = state.filters.all.filter(\.isActive)
		return .send(.delegate(.updateActiveFilters(activeFilters)))
	}
}

extension TransactionHistoryFilters.State {
	mutating func setActive(_ active: Bool, filter: TransactionFilter) {
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

extension TransactionHistoryFilters.State.Filters {
	typealias Filter = TransactionHistoryFilters.State.Filter
	init(transferTypes: [Filter], fungibles: [Filter], nonFungibles: [Filter], transactionTypes: [Filter]) {
		self.transferTypes = transferTypes.asIdentifiable()
		self.fungibles = fungibles.asIdentifiable()
		self.nonFungibles = nonFungibles.asIdentifiable()
		self.transactionTypes = transactionTypes.asIdentifiable()
	}
}

extension TransactionHistoryFilters.State.Filter {
	init(_ transferType: TransactionFilter.TransferType, isActive: Bool) {
		self.init(
			id: .transferType(transferType),
			icon: Self.icon(for: transferType),
			label: Self.label(for: transferType),
			isActive: isActive
		)
	}

	private static func icon(for transferType: TransactionFilter.TransferType) -> ImageResource {
		switch transferType {
		case .withdrawal:
			.transactionHistoryWithdrawal
		case .deposit:
			.transactionHistoryDeposit
		}
	}

	// FIXME: Strings
	private static func label(for transferType: TransactionFilter.TransferType) -> String {
		switch transferType {
		case .withdrawal:
			"Withdrawals"
		case .deposit:
			"Deposits"
		}
	}

	init?(_ asset: OnLedgerEntity.Resource, isActive: Bool) {
		let label = asset.metadata.title ?? asset.resourceAddress.formatted()
		self.init(id: .asset(asset.resourceAddress), icon: nil, label: label, isActive: isActive)
	}

	init(_ transactionType: TransactionFilter.TransactionType, isActive: Bool) {
		self.init(
			id: .transactionType(transactionType),
			icon: nil,
			label: Self.label(for: transactionType),
			isActive: isActive
		)
	}

	// FIXME: Strings
	private static func label(for transactionType: TransactionFilter.TransactionType) -> String {
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

extension IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> {
	/// Sets the `isActive` flag of the filter with the given id to `active`, and all others to `false`
	mutating func setActive(_ id: TransactionFilter, active: Bool) {
		for existingID in ids {
			self[id: existingID]?.isActive = existingID == id ? active : false
		}
	}
}
