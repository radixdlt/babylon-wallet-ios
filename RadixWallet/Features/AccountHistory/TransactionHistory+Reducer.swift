import ComposableArchitecture

private extension Date {
	// September 28th, 2023, at 9.30 PM UTC
	static let babylonLaunch = Date(timeIntervalSince1970: 1_695_893_400)
}

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let availableMonths: [DateRangeItem]

		let account: Profile.Network.Account

		let portfolio: OnLedgerEntity.Account

		var resources: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		var activeFilters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> = []

		var sections: IdentifiedArrayOf<TransactionSection> = []

		// The currently selected month
		var currentMonth: DateRangeItem.ID

		var loading: Loading = .init(parameters: .init(period: Date.now ..< Date.now))

		var visibleSections: Set<TransactionSection.ID> = []

		struct Loading: Hashable, Sendable {
			let parameters: TransactionHistoryParameters
			var isLoading: Bool = false
			var nextCursor: String?
		}

		@PresentationState
		public var destination: Destination.State?

		init(account: Profile.Network.Account) throws {
			@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

			guard let portfolio = accountPortfoliosClient.portfolios().first(where: { $0.address == account.address }) else {
				struct MissingPortfolioError: Error { let account: AccountAddress }
				throw MissingPortfolioError(account: account.accountAddress)
			}

			self.availableMonths = try .from(.babylonLaunch)
			self.account = account
			self.portfolio = portfolio
			self.currentMonth = availableMonths[availableMonths.endIndex - 1].id
		}

		public struct TransactionSection: Sendable, Hashable, Identifiable {
			public var id: Tagged<Self, Date> { .init(day) }
			/// The day, in the form of a `Date` with all time components set to 0
			let day: Date
			/// The month, in the form of a `Date` with all time components set to 0 and the day set to 1
			let month: Date
			var transactions: [TransactionHistoryItem]
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case onAppear
		case selectedMonth(DateRangeItem.ID)
		case filtersTapped
		case filterCrossTapped(TransactionFilter)
		case closeTapped

		case sectionAppeared(State.TransactionSection.ID)
		case sectionDisappeared(State.TransactionSection.ID)

		case reachedTop
		case reachedEnd
	}

	public enum InternalAction: Sendable, Hashable {
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
//			return loadHistory(parameters: .init(period: .babylonLaunch ..< .now), state: &state)
			return loadHistory(parameters: .init(period: .init(timeIntervalSinceNow: -5 * 24 * 3600) ..< .now), state: &state)

		case let .selectedMonth(month):
			state.currentMonth = month
//			return loadHistory(state: &state)
			return .none

		case .filtersTapped:
			state.destination = .filters(.init(portfolio: state.portfolio, filters: state.activeFilters.map(\.id)))
			return .none

		case let .filterCrossTapped(id):
			state.activeFilters.remove(id: id)

			// RELOAD HISTORY with new parameters
			return loadHistory(filters: state.activeFilters.map(\.id), state: &state)

		case .closeTapped:
			return .run { _ in await dismiss() }

		case let .sectionAppeared(id):
			state.visibleSections.insert(id)

			print("•••• + \(state.visibleSections.sorted(by: \.rawValue).map { $0.rawValue.formatted(date: .abbreviated, time: .omitted) })")

			if id == state.sections.last?.id {
				// LOAD MORE HISTORY backwards
//				print("••• LOAD MORE BACKWARDS")
//				return loadHistory(state: &state)
			} else if id == state.sections.first?.id {
				// LOAD MORE HISTORY forwards
//				print("••• LOAD MORE FORWARDS")
			}

			return .none

		case let .sectionDisappeared(id):
			state.visibleSections.remove(id)
			print("•••• - \(state.visibleSections.sorted(by: \.rawValue).map { $0.rawValue.formatted(date: .abbreviated, time: .omitted) })")
			return .none

		case .reachedTop:
			print("•• Reached TOP")
			return .none

		case .reachedEnd:
			print("•• Reached END")
			return loadMoreHistory(state: &state)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
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
		// RELOAD USING PARAMETERS
		loadHistory(filters: state.activeFilters.map(\.id), state: &state)
	}

	// Helper methods

	func loadHistory(filters: [TransactionFilter], state: inout State) -> Effect<Action> {
		let parameters = TransactionHistoryParameters(
			period: state.loading.parameters.period,
			backwards: true,
			filters: filters
		)
		return loadHistory(parameters: parameters, state: &state)
	}

	func loadMoreHistory(state: inout State) -> Effect<Action> {
		loadHistory(parameters: state.loading.parameters, state: &state)
	}

	func loadHistory(parameters: TransactionHistoryParameters, state: inout State) -> Effect<Action> {
		if state.loading.nextCursor == nil, state.loading.parameters.covers(parameters) {
			print("•• ALREADY FULLY LOADED")
			return .none
		}

		if parameters != state.loading.parameters {
			state.sections = []
			print("•• Reload from scratch")
		} else {
			if state.loadedRange == nil, state.loading.nextCursor == nil {
				print("•• Load first")
			} else {
				print("•• Load more of the same")
			}
		}

		state.loading.isLoading = true

		print("•• Load \(parameters.period.debugString()), \(parameters.filters.count) filters. HAVE \(state.loadedRange?.debugString() ?? "---")")

		let request = TransactionHistoryRequest(
			account: state.account.accountAddress,
			parameters: parameters,
			cursor: state.loading.nextCursor,
			allResourcesAddresses: state.portfolio.allResourceAddresses,
			resources: state.resources
		)

		return .run { send in
			let response = try await transactionHistoryClient.getTransactionHistory(request)
			await send(.internal(.loadedHistory(response)))
		}
	}

	func debugPrint(_ response: TransactionHistoryResponse, loadedRange: Range<Date>?) {
		let times = response.items.map(\.time)
		let newlyLoadedRange: String = if let lowest = times.min(), let highest = times.max() {
			(lowest ..< highest).debugString() + " (#\(response.items.count) of \(response.totalCount ?? -1))"
		} else {
			"(nothing out of \(response.totalCount ?? -1))"
		}
		if let loadedRange {
			print("••• Loaded \(newlyLoadedRange) from \(response.parameters.period.debugString()): HAD \(loadedRange.debugString())")
		} else {
			print("••• Loaded \(newlyLoadedRange) from \(response.parameters.period.debugString())")
		}
	}

	func loadedHistory(_ response: TransactionHistoryResponse, state: inout State) -> Effect<Action> {
		state.resources.append(contentsOf: response.resources)

		state.loading.isLoading = false

		if response.parameters == state.loading.parameters {
			debugPrint(response, loadedRange: state.loadedRange) // FIXME: GK remove

			// We loaded more from the same range
			state.loading.nextCursor = response.nextCursor

			guard response.parameters.backwards else {
				print(" •• forward loading not supported yet")
				return .none
			}

			state.sections.addItems(response.items)

			state.loading.isLoading = false
		} else {
			print("••• Loaded: \(response.parameters.period.debugString()) :#\(response.items.count) of \(response.totalCount ?? -1)")
			state.loading = .init(parameters: response.parameters, nextCursor: response.nextCursor)
			state.sections.replaceItems(response.items)
		}

//		let totalTransactions = state.sections.reduce(0) { $0 + $1.transactions.count }
//
//		print(" •• Next cursor: \(response.nextCursor ?? "nil") : totalLoaded \(totalTransactions) out of \(response.totalCount.map(String.init) ?? "nil")")
//
//		if response.nextCursor == nil || let totalCount = response.totalCount, Int64(totalTransactions) >= totalCount {
//			print(" •• Has now loaded all (exact: \(Int64(totalTransactions) == totalCount))")
//			state.loading.loadedAll = true
//			state.loading.cursor = nil
//		}

		return .none
	}
}

// MARK: - TransactionHistory.State.TransactionSection + CustomStringConvertible
extension TransactionHistory.State.TransactionSection: CustomStringConvertible {
	public var description: String {
		"Section(\(id.rawValue.formatted(date: .numeric, time: .omitted))): \(transactions.count) transactions"
	}
}

extension TransactionHistory.State {
	var loadedRange: Range<Date>? {
		guard let first = sections.first?.transactions.first?.time, let last = sections.last?.transactions.last?.time else {
			return nil
		}
		return last ..< first
	}
}

extension Range {
	func contains(_ otherRange: Range) -> Bool {
		otherRange.lowerBound >= lowerBound && otherRange.upperBound <= upperBound
	}
}

extension Range<Date> {
	func debugString(style: Date.FormatStyle.DateStyle = .abbreviated) -> String {
		"\(lowerBound.formatted(date: style, time: .omitted)) -- \(upperBound.formatted(date: style, time: .omitted))"
	}

	var clamped: Range? {
		let now: Date = .now
		guard lowerBound < now else { return nil }
		return lowerBound ..< Swift.min(upperBound, now)
	}
}

extension IdentifiedArrayOf<TransactionHistory.State.TransactionSection> {
	mutating func addItems(_ items: some Collection<TransactionHistoryItem>) {
		let newSections = items.inUnsortedSections.sorted(by: \.day, >)

		print(" ••• got # \(items.count)")

		for newSection in newSections {
			if last?.id == newSection.id {
				print("   ••• appending # \(newSection.transactions.count) to existing section \(self[id: newSection.id]!)")

//				if let last = self[id: newSection.id]?.transactions.last?.time {
//					print("    •••• last existing transaction at \(last.formatted(date: .abbreviated, time: .shortened))")
//				}

				self[id: newSection.id]?.transactions.append(contentsOf: newSection.transactions)
			} else {
				print("   ••• appending entire section \(newSection)")
				append(newSection)
			}
		}
	}

	mutating func replaceItems(_ items: some Collection<TransactionHistoryItem>) {
		self = items.inUnsortedSections.sorted(by: \.day, >).asIdentifiable()
	}
}

extension Collection<TransactionHistoryItem> {
	var inUnsortedSections: [TransactionHistory.State.TransactionSection] {
		let calendar: Calendar = .current
		return Dictionary(grouping: self) { transaction in
			calendar.startOfDay(for: transaction.time)
		}
		.map { day, transactions in
			.init(
				day: day,
				month: calendar.startOfMonth(for: day),
				transactions: transactions
			)
		}
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
