import ComposableArchitecture

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let availableMonths: [DateRangeItem]

		var resources: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		var activeFilters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> = []

		var sections: IdentifiedArrayOf<TransactionSection> = []

		// The currently selected month
		var currentMonth: DateRangeItem.ID

		var loading: Loading

		struct Loading: Hashable, Sendable {
			let range: Range<Date>
			let filters: [TransactionFilter]
			var didLoadResources: Bool = false
			var loadedRange: Range<Date>
			var cursor: String?
			var isLoading: Bool

			static func start(_ fromDate: Date) -> Self {
				.init(range: fromDate ..< Date.now, filters: [], loadedRange: Date.now ..< Date.now, isLoading: true)
			}
		}

		@PresentationState
		public var destination: Destination.State?

		init(account: Profile.Network.Account) throws {
			var account = account
			if account.networkID == .mainnet {
				account = .init(
					networkID: account.networkID,
					address: try! AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l"),
					securityState: account.securityState,
					appearanceID: account.appearanceID,
					displayName: account.displayName
				)
			}

			self.account = account
			self.availableMonths = try .from(babylonDate)
			self.currentMonth = availableMonths[availableMonths.endIndex - 1].id
			self.loading = .start(babylonDate)
		}

		public struct TransactionSection: Sendable, Hashable, Identifiable {
			public var id: Date { day }
			/// The day, in the form of a `Date` with all time components set to 0
			let day: Date
			/// The month, in the form of a `Date` with all time components set to 0 and the day set to 1
			let month: Date
			var transactions: [TransactionHistoryItem]
		}

		// September 28th, 2023, at 9.30 PM UTC
		private let babylonDate = Date(timeIntervalSince1970: 1_695_893_400)
	}

	public enum ViewAction: Sendable, Hashable {
		case onAppear
		case selectedMonth(DateRangeItem.ID)
		case filtersTapped
		case filterCrossTapped(TransactionFilter)
		case closeTapped
	}

	public enum InternalAction: Sendable, Hashable {
		case loadedResources(IdentifiedArrayOf<OnLedgerEntity.Resource>)
		case loadedHistory(TransactionHistoryResponse)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case filters(TransactionHistoryFilters.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case filters(TransactionHistoryFilters.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.filters, action: \.filters) {
				TransactionHistoryFilters()
			}
		}
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionHistoryClient) var transactionHistoryClient
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onAppear:
			return loadResources(state: state)

		case let .selectedMonth(month):
			state.currentMonth = month
			return loadHistory(state: &state)

		case .filtersTapped:
			guard state.loading.didLoadResources else {
				loggerGlobal.error("The filters button should not be enabled until the resources have been loaded")
				return .none
			}
			state.destination = .filters(.init(assets: state.resources, filters: state.activeFilters.map(\.id)))
			return .none

		case let .filterCrossTapped(id):
			state.activeFilters.remove(id: id)
			return loadHistory(state: &state)

		case .closeTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedResources(resources):
			loadedResources(resources, state: &state)
		case let .loadedHistory(history):
			loadedHistory(history, state: &state)
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .filters(.delegate(.updateActiveFilters(filters))):
			state.activeFilters = filters
			return .none
		default:
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		loadHistory(state: &state)
	}

	// Helper methods

	func loadResources(state: State) -> Effect<Action> {
		.run { [account = state.account.address] send in
			let resources = try await accountPortfoliosClient.fetchAccountPortfolio(account, false).allResources
			await send(.internal(.loadedResources(resources)))
		}
	}

	func loadedResources(_ resources: IdentifiedArrayOf<OnLedgerEntity.Resource>, state: inout State) -> Effect<Action> {
		state.resources = resources
		state.loading.didLoadResources = true
		return loadHistory(state: &state)
	}

	func loadHistory(state: inout State) -> Effect<Action> {
		state.loading.isLoading = true
		guard let range = state.availableMonths.first(where: { $0.id == state.currentMonth })?.range.clamped else {
			return .none
		}

		guard state.loading.didLoadResources else {
			return loadResources(state: state)
		}

//		let mockAccount = state.account.networkID == .mainnet ? try! AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l") : nil

		let request = TransactionHistoryRequest(
			account: state.account.accountAddress,
			period: range,
			filters: state.activeFilters.map(\.id),
			allResources: state.resources,
			ascending: false,
			cursor: nil
		)

		return .run { send in
			let response = try await transactionHistoryClient.getTransactionHistory(request)
			await send(.internal(.loadedHistory(response)))
		}
	}

	func loadedHistory(_ response: TransactionHistoryResponse, state: inout State) -> Effect<Action> {
		state.loading.isLoading = false
//		state.resources = response.allResources

//		let newSections = transactions.inSections
//		var sections = self.sections
//		sections.append(contentsOf: newSections)
//		sections.sort(by: \.day)
//		self.sections = sections
//		loadedPeriods.append(contentsOf: newSections.map(\.month))

		state.sections.removeAll()
		state.sections.append(contentsOf: response.items.inSections)
		state.sections.sort(by: \.day)
//		loadedPeriods.append(contentsOf: sections.map(\.month))

		print("••• UPDATED history, set res: \(response.allResources.count)")

		return .none
	}
}

extension OnLedgerEntity.Account {
	var allResources: IdentifiedArrayOf<OnLedgerEntity.Resource> {
		var result: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		if let xrd = fungibleResources.xrdResource {
			result.append(xrd.resource)
		}
		result.append(contentsOf: fungibleResources.nonXrdResources.map(\.resource))
		result.append(contentsOf: nonFungibleResources.map(\.resource))
		result.append(contentsOf: poolUnitResources.poolUnits.map(\.resource.resource))

		for stake in poolUnitResources.radixNetworkStakes {
			if let stakeClaim = stake.stakeClaimResource {
				result.append(stakeClaim.resource)
			}
			if let stakeUnit = stake.stakeUnitResource {
				result.append(stakeUnit.resource)
			}
		}

		return result
	}
}

private extension OnLedgerEntity.OwnedFungibleResource {
	var resource: OnLedgerEntity.Resource {
		.init(resourceAddress: resourceAddress, atLedgerState: atLedgerState, metadata: metadata)
	}
}

private extension OnLedgerEntity.OwnedNonFungibleResource {
	var resource: OnLedgerEntity.Resource {
		.init(resourceAddress: resourceAddress, atLedgerState: atLedgerState, metadata: metadata)
	}
}

private extension Range<Date> {
	var clamped: Range? {
		let now: Date = .now
		guard lowerBound < now else { return nil }
		return lowerBound ..< Swift.min(upperBound, now)
	}
}

extension [TransactionHistoryItem] {
	var inSections: [TransactionHistory.State.TransactionSection] {
		let calendar: Calendar = .current

		let sortedBackwards = sorted(by: \.time, >)
		var result: [TransactionHistory.State.TransactionSection] = []

		for transaction in sortedBackwards {
			let day = calendar.startOfDay(for: transaction.time)
			let month = calendar.startOfMonth(for: transaction.time)

			if result.last?.day == day {
				result[result.endIndex - 1].append(transaction)
			} else {
				result.append(.init(day: day, month: month, transactions: [transaction]))
			}
		}
		return result
	}
}

extension TransactionHistory.State.TransactionSection {
	mutating func append(_ transaction: TransactionHistoryItem) {
		transactions.append(transaction)
	}
}

// MARK: - FailedToCalculateDate
struct FailedToCalculateDate: Error {}

extension [DateRangeItem] {
	static func from(_ fromDate: Date) throws -> Self {
		let now: Date = .now
		let calendar: Calendar = .current

		var monthStarts = [calendar.startOfMonth(for: fromDate)]
		repeat {
			let lastMonthStart = monthStarts[monthStarts.endIndex - 1]
			guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: lastMonthStart) else {
				throw FailedToCalculateDate() // This should not be possible
			}
			monthStarts.append(nextMonthStart)
		} while monthStarts[monthStarts.endIndex - 1] < now

		func caption(date: Date) -> String {
			if calendar.areSameYear(date, now) {
				Self.sameYearFormatter.string(from: date)
			} else {
				Self.otherYearFormatter.string(from: date)
			}
		}

		return zip(monthStarts, monthStarts.dropFirst()).map { start, end in
			.init(
				caption: caption(date: start),
				startDate: start,
				endDate: end
			)
		}
	}

	private static let sameYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateFormat = "MMM"
		return formatter
	}()

	private static let otherYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .none
		formatter.dateFormat = "MMM YY"
		return formatter
	}()
}

extension Calendar {
	func areSameYear(_ date: Date, _ otherDate: Date) -> Bool {
		component(.year, from: date) == component(.year, from: otherDate)
	}

	func startOfMonth(for date: Date) -> Date {
		var components = dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
		components.day = 1
		components.hour = 0
		components.minute = 0
		components.second = 0
		components.nanosecond = 0

		guard let start = self.date(from: components) else {
			assertionFailure("Could not create date from \(components)")
			loggerGlobal.error("Could not create date from \(components)")
			return date
		}

		return start
	}
}
