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

		public init(portfolio: OnLedgerEntity.Account, filters: [Filter.ID]) {
			let transferTypes = TransactionFilter.TransferType.allCases.map { Filter($0, isActive: filters.contains(.transferType($0))) }
			let fungibles = portfolio.fungibleMetadata.map { Filter($0.key, metadata: $0.value, isActive: filters.contains(.asset($0.key))) }
			let nonFungibles = portfolio.nonFungibleMetadata.map { Filter($0.key, metadata: $0.value, isActive: filters.contains(.asset($0.key))) }
			let transactionTypes = TransactionFilter.TransactionType.allCases.map { Filter($0, isActive: filters.contains(.transactionType($0))) }

			self.filters = .init(transferTypes: transferTypes, fungibles: fungibles, nonFungibles: nonFungibles, transactionTypes: transactionTypes)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case filterTapped(TransactionFilter)
		case clearAllTapped
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

		case .clearAllTapped:
			for id in state.filters.all.ids {
				state.setActive(false, filter: id)
			}
			return activeFiltersChanged(state: state)

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
		self.transferTypes = transferTypes.asIdentified()
		self.fungibles = fungibles.asIdentified()
		self.nonFungibles = nonFungibles.asIdentified()
		self.transactionTypes = transactionTypes.asIdentified()
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
			.transactionHistoryFilterWithdrawal
		case .deposit:
			.transactionHistoryFilterDeposit
		}
	}

	private static func label(for transferType: TransactionFilter.TransferType) -> String {
		switch transferType {
		case .withdrawal:
			L10n.TransactionHistory.Filters.withdrawalsType
		case .deposit:
			L10n.TransactionHistory.Filters.depositsType
		}
	}

	init(_ resourceAddress: ResourceAddress, metadata: OnLedgerEntity.Metadata, isActive: Bool) {
		let label = metadata.title ?? resourceAddress.formatted()
		self.init(id: .asset(resourceAddress), icon: nil, label: label, isActive: isActive)
	}

	init(_ transactionType: TransactionFilter.TransactionType, isActive: Bool) {
		self.init(
			id: .transactionType(transactionType),
			icon: nil,
			label: TransactionHistory.label(for: transactionType),
			isActive: isActive
		)
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

private extension OnLedgerEntity.Account {
	var fungibleMetadata: [ResourceAddress: OnLedgerEntity.Metadata] {
		var result: [ResourceAddress: OnLedgerEntity.Metadata] = [:]

		if let xrd = fungibleResources.xrdResource {
			result[xrd.resourceAddress] = xrd.metadata
		}
		for fungible in fungibleResources.nonXrdResources {
			result[fungible.resourceAddress] = fungible.metadata
		}

		return result
	}

	var nonFungibleMetadata: [ResourceAddress: OnLedgerEntity.Metadata] {
		var result: [ResourceAddress: OnLedgerEntity.Metadata] = [:]

		for nonFungible in nonFungibleResources {
			result[nonFungible.resourceAddress] = nonFungible.metadata
		}

		return result
	}
}
