import ComposableArchitecture

// MARK: - Triggering
// Triggers a View update, even if the value wasn't changed
struct Triggering<T: Hashable & Sendable>: Hashable, Sendable {
	let created: Date = .now
	let value: T
}

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public enum Direction: Sendable {
		case up
		case down
	}

	public enum ScrollTarget: Hashable, Sendable {
		case transaction(TXID)
		// The latest transaction before the given date
		case beforeDate(Date)
	}

	public struct State: Sendable, Hashable {
		var fullPeriod: Range<Date> = .now ..< .now

		var availableMonths: [DateRangeItem] = []

		let account: Profile.Network.Account

		let portfolio: OnLedgerEntity.Account

		var resources: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		var activeFilters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> = []

		var sections: IdentifiedArrayOf<TransactionSection> = []

		var scrollTarget: Triggering<TXID?> = .init(value: nil)

		/// The currently selected month
		var currentMonth: DateRangeItem.ID

		/// Values related to loading. Note that `parameters` are set **when receiving the response**
		var loading: Loading = .init(pivotDate: .now, filters: [])

		/// Workaround, TCA sends the sectionDisappeared after we dismiss, causing a run-time warning
		var didDismiss: Bool = false

		struct Loading: Hashable, Sendable {
			let pivotDate: Date
			let filters: [TransactionFilter]

			var isLoading: Bool = false
			var upCursor: Cursor = .initialRequest
			var downCursor: Cursor = .initialRequest

			public enum Cursor: Hashable, Sendable {
				case initialRequest
				case next(String)
				case loadedAll
			}
		}

		@PresentationState
		public var destination: Destination.State?

		init(account: Profile.Network.Account) throws {
			@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

			guard let portfolio = accountPortfoliosClient.portfolios().first(where: { $0.account.address == account.address }) else {
				struct MissingPortfolioError: Error { let account: AccountAddress }
				throw MissingPortfolioError(account: account.accountAddress)
			}

			self.account = account
			self.portfolio = portfolio.account
			self.currentMonth = .distantFuture
		}
	}

	public struct TransactionSection: Sendable, Hashable, Identifiable {
		public var id: Tagged<Self, Date> { .init(day) }
		/// The day, in the form of a `Date` with all time components set to 0
		let day: Date
		/// The month, in the form of a `Date` with all time components set to 0 and the day set to 1
		let month: Date
		var transactions: IdentifiedArrayOf<TransactionHistoryItem>
	}

	public enum ViewAction: Sendable, Hashable {
		case onAppear
		case selectedMonth(DateRangeItem.ID)
		case filtersTapped
		case filterCrossTapped(TransactionFilter)
		case transactionsTableAction(TableView.Action)
		case closeTapped
	}

	public enum InternalAction: Sendable, Hashable {
		case loadedFirstTransactionDate(Date?)
		case loadedHistory(
			TransactionHistoryResponse,
			parameters: TransactionHistoryRequest.Parameters,
			scrollTarget: ScrollTarget?
		)
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
	@Dependency(\.openURL) var openURL

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
			return .run { [accountAddress = state.account.accountAddress] send in
				let date = try await transactionHistoryClient.getFirstTransactionDate(accountAddress)
				await send(.internal(.loadedFirstTransactionDate(date)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .selectedMonth(month):
			state.currentMonth = month
			return loadTransactionsForMonth(month, state: &state)

		case .filtersTapped:
			state.destination = .filters(.init(portfolio: state.portfolio, filters: state.activeFilters.map(\.id)))
			return .none

		case let .filterCrossTapped(id):
			state.activeFilters.remove(id: id)
			return loadTransactionsWithFilters(state.activeFilters.map(\.id), state: &state)

		case .closeTapped:
			state.didDismiss = true
			return .run { _ in await dismiss() }

		case let .transactionsTableAction(action):
			switch action {
			case .reachedTop:
				return loadNewerTransactions(state: &state)

			case .pulledDown:
				return loadNewerTransactions(state: &state)

			case .nearingBottom:
				return loadTransactions(state: &state)

			case .reachedBottom:
				return loadTransactions(state: &state)

			case let .monthChanged(month):
				state.currentMonth = month
				return .none

			case let .transactionTapped(txid):
				let path = "transaction/\(txid.asStr())/summary"
				let url = Radix.Dashboard.dashboard(forNetworkID: state.account.networkID).url.appending(path: path)
				return .run { _ in
					await openURL(url)
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedFirstTransactionDate(date):
			let lastDate: Date = .init(timeIntervalSinceNow: -10)
			let firstDate = date ?? lastDate
			state.fullPeriod = firstDate ..< lastDate
			state.availableMonths = (try? .init(period: state.fullPeriod)) ?? []

			if let latestMonth = state.availableMonths.last?.id {
				state.currentMonth = latestMonth
			}
			return loadTransactions(state: &state)

		case let .loadedHistory(response, parameters, scrollTarget):
			loadedHistory(response, parameters: parameters, scrollTarget: scrollTarget, state: &state)

			// IF we stil haven't loaded anything later than the pivot date, we will do so now
			let upwardsPeriod = state.requestParameters(for: .up).period
			if !upwardsPeriod.isEmpty, let lastLoaded = state.sections.dateSpan?.upperBound, !upwardsPeriod.contains(lastLoaded) {
				return loadNewerTransactions(state: &state)
			}

			return .none
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
		loadTransactionsWithFilters(state.activeFilters.map(\.id), state: &state)
	}

	// Helper methods

	/// Load history for the previously selected period, using the provided filters
	func loadTransactionsWithFilters(_ filters: [TransactionFilter], state: inout State) -> Effect<Action> {
		guard filters != state.loading.filters else { return .none }
		state.loading = state.loading.withNewFilters(filters)
		return loadTransactionsForMonth(state.currentMonth, state: &state)
	}

	/// Load history for the provided month, keeping the same period and filters
	func loadTransactionsForMonth(_ month: Date, state: inout State) -> Effect<Action> {
		guard let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: month) else { return .none }
		let clampedEndOfMonth = min(endOfMonth, state.fullPeriod.upperBound)

		if state.sections.dateSpan?.contains(month ..< clampedEndOfMonth) == true {
			state.setScrollTarget(.beforeDate(clampedEndOfMonth))
			return .none
		}

		state.sections = []
		state.loading = state.loading.withNewPivotDate(clampedEndOfMonth)
		return loadHistory(.down, scrollTarget: .beforeDate(clampedEndOfMonth), state: &state)
	}

	/// Loads (more) transactions
	func loadTransactions(state: inout State) -> Effect<Action> {
		loadHistory(.down, state: &state)
	}

	func loadNewerTransactions(state: inout State) -> Effect<Action> {
		loadHistory(.up, scrollTarget: (state.sections.first?.transactions.first?.id).map(ScrollTarget.transaction), state: &state)
	}

	/// Makes the TransactionHitosryRequest. **NB: don't call this directly**, instead use the specialised functions like `loadHistoryForMonth`
	func loadHistory(_ direction: Direction, scrollTarget: ScrollTarget? = nil, state: inout State) -> Effect<Action> {
		let parameters = state.requestParameters(for: direction)
		let cursor = state.loading[cursor: direction]
		guard !state.loading.isLoading, cursor != .loadedAll, !parameters.period.isEmpty else { return .none }

		state.loading.isLoading = true

		let request = TransactionHistoryRequest(
			account: state.account.accountAddress,
			parameters: parameters,
			cursor: cursor.string,
			allResourcesAddresses: state.portfolio.allResourceAddresses,
			resources: state.resources
		)

		return .run { send in
			let response = try await transactionHistoryClient.getTransactionHistory(request)
			await send(.internal(
				.loadedHistory(response, parameters: request.parameters, scrollTarget: scrollTarget)
			))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func loadedHistory(
		_ response: TransactionHistoryResponse,
		parameters: TransactionHistoryRequest.Parameters,
		scrollTarget: ScrollTarget?,
		state: inout State
	) {
		guard parameters == state.requestParameters(for: parameters.direction) else {
			loggerGlobal.info("Received obsolete Transaction History response, should not be possible")
			return
		}
		state.resources.append(contentsOf: response.resources)
		state.loading[cursor: parameters.direction] = response.nextCursor.map { .next($0) } ?? .loadedAll
		state.sections.addTransactions(response.items)
		state.loading.isLoading = false
		state.setScrollTarget(scrollTarget)
	}
}

extension StoreOf<TransactionHistory> {
	var bannerStore: Store<Bool, Never> {
		scope(state: \.isNonMainNetAccount, action: \.never)
	}
}

extension TransactionHistory.State {
	var isNonMainNetAccount: Bool {
		account.networkID != .mainnet
	}

	mutating func setScrollTarget(_ scrollTarget: TransactionHistory.ScrollTarget?) {
		if let scrollTarget {
			switch scrollTarget {
			case let .transaction(txID):
				self.scrollTarget = .init(value: txID)
			case let .beforeDate(date):
				if let lastSection = sections.first(where: { $0.day < date }), let lastTransaction = lastSection.transactions.first {
					self.currentMonth = lastSection.month
					self.scrollTarget = .init(value: lastTransaction.id)
				}
			}
		} else {
			self.scrollTarget = .init(value: nil)
		}
	}

	func requestParameters(for direction: TransactionHistory.Direction) -> TransactionHistoryRequest.Parameters {
		.init(
			period: fullPeriod.split(before: direction == .down, point: loading.pivotDate),
			filters: loading.filters,
			direction: direction
		)
	}
}

extension TransactionHistory.State.Loading {
	func withNewPivotDate(_ newPivotDate: Date) -> Self {
		.init(pivotDate: newPivotDate, filters: filters)
	}

	func withNewFilters(_ newFilters: [TransactionFilter]) -> Self {
		.init(pivotDate: pivotDate, filters: newFilters)
	}

	subscript(cursor direction: TransactionHistory.Direction) -> Cursor {
		get {
			switch direction {
			case .up: upCursor
			case .down: downCursor
			}
		}
		set {
			switch direction {
			case .up:
				upCursor = newValue
			case .down:
				downCursor = newValue
			}
		}
	}
}

extension TransactionHistory.State.Loading.Cursor {
	var string: String? {
		guard case let .next(value) = self else { return nil }
		return value
	}
}

// MARK: - TransactionHistory.TransactionSection + CustomStringConvertible
extension TransactionHistory.TransactionSection: CustomStringConvertible {
	public var description: String {
		"Section(\(id.rawValue.formatted(date: .numeric, time: .omitted))): \(transactions.count) transactions"
	}
}

extension Range {
	func contains(_ otherRange: Range) -> Bool {
		otherRange.lowerBound >= lowerBound && otherRange.upperBound <= upperBound
	}

	/// Returns the part of the range that is before (or after, respectivel) the provided point
	func split(before: Bool, point: Bound) -> Range {
		let clamped = Swift.min(Swift.max(point, lowerBound), upperBound)
		return before ? lowerBound ..< clamped : clamped ..< upperBound
	}
}

extension Range<Date> {
	var debugString: String {
		"\(lowerBound.formatted(date: .abbreviated, time: .omitted)) -- \(upperBound.formatted(date: .abbreviated, time: .omitted))"
	}
}

extension RandomAccessCollection<TransactionHistory.TransactionSection> {
	var dateSpan: Range<Date>? {
		guard let first = first?.transactions.first?.time, let last = last?.transactions.last?.time else {
			return nil
		}
		return last ..< first
	}
}

extension IdentifiedArrayOf<TransactionHistory.TransactionSection> {
	mutating func addTransactions(_ transactions: some Collection<TransactionHistoryItem>) {
		let calendar: Calendar = .current
		let grouped = Dictionary(grouping: transactions) { transaction in
			calendar.startOfDay(for: transaction.time)
		}

		for (day, transactions) in grouped {
			let sectionID = TransactionHistory.TransactionSection.ID(day)
			if self[id: sectionID] == nil {
				let month = calendar.startOfMonth(for: day)
				self[id: sectionID] = .init(day: day, month: month, transactions: transactions.asIdentifiable())
			} else {
				self[id: sectionID]?.transactions.append(contentsOf: transactions)
			}
			self[id: sectionID]?.transactions.sort(by: \.time, >)
		}

		sort(by: \.day, >)
	}
}

// MARK: - FailedToCalculateDate
struct FailedToCalculateDate: Error {}

extension [DateRangeItem] {
	init(period: Range<Date>) throws {
		guard !period.isEmpty else {
			self = []
			return
		}

		let calendar: Calendar = .current

		var monthStarts = [calendar.startOfMonth(for: period.lowerBound)]
		repeat {
			let lastMonthStart = monthStarts[monthStarts.endIndex - 1]
			guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: lastMonthStart) else {
				throw FailedToCalculateDate() // This should not be possible
			}
			monthStarts.append(nextMonthStart)
		} while monthStarts[monthStarts.endIndex - 1] < period.upperBound

		func caption(date: Date) -> String {
			if calendar.areSameYear(date, .now) {
				Self.sameYearFormatter.string(from: date)
			} else {
				Self.otherYearFormatter.string(from: date)
			}
		}

		self = zip(monthStarts, monthStarts.dropFirst()).map { start, end in
			.init(
				caption: caption(date: start),
				startDate: start,
				endDate: end
			)
		}
	}

	private static let sameYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = .localizedStringWithFormat("MMM")

		return formatter
	}()

	private static let otherYearFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = .localizedStringWithFormat("MMM YY")
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
