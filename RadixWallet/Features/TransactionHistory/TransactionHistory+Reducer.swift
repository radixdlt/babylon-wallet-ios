import ComposableArchitecture

// MARK: - Triggering
// Triggers a View update, even if the value wasn't changed
struct Triggering<T: Hashable & Sendable>: Hashable, Sendable {
	let created: Date = .now
	let value: T

	private init(value: T) {
		self.value = value
	}

	static func updated(_ value: T) -> Self {
		.init(value: value)
	}
}

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public enum Direction: Sendable {
		case up
		case down
	}

	public enum ScrollTarget: Hashable, Sendable {
		case transaction(IntentHash)
		// The latest transaction before the given date
		case beforeDate(Date)
		case latestTransaction
	}

	public struct State: Sendable, Hashable {
		var fullPeriod: Range<Date> = .now ..< .now

		var availableMonths: IdentifiedArrayOf<DateRangeItem> = []

		let account: Profile.Network.Account

		let portfolio: OnLedgerEntity.Account

		var resources: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		var activeFilters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> = []

		var sections: IdentifiedArrayOf<TransactionSection> = []

		var scrollTarget: Triggering<IntentHash?> = .updated(nil)

		/// The currently selected month
		var currentMonth: DateRangeItem.ID

		/// Values related to loading. Note that `parameters` are set **when receiving the response**
		var loading: Loading = .init(pivotDate: nil, filters: [])

		/// Workaround, TCA sends the sectionDisappeared after we dismiss, causing a run-time warning
		var didDismiss: Bool = false

		struct Loading: Hashable, Sendable {
			let pivotDate: Date? // nil means "now"
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
			state.loading.isLoading = true
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
				let path = "transaction/\(txid.bech32EncodedTxId)/summary"
				let url = Radix.Dashboard.dashboard(forNetworkID: state.account.networkID).url.appending(path: path)
				return .run { _ in
					await openURL(url)
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedFirstTransactionDate(firstDate):
			state.loading.isLoading = false
			guard let firstDate else { return .none }
			state.fullPeriod = firstDate ..< .now
			state.availableMonths = (try? .init(period: state.fullPeriod)) ?? []

			return loadTransactionsFirstTime(state: &state)

		case let .loadedHistory(response, parameters, scrollTarget):
			loadedHistory(response, parameters: parameters, scrollTarget: scrollTarget, state: &state)

			// If we stil haven't loaded anything later than the pivot date, we will do so now
			if state.shouldAlsoLoadUpwards {
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

	func loadTransactionsFirstTime(state: inout State) -> Effect<Action> {
		loadHistory(.down, scrollTarget: .latestTransaction, state: &state)
	}

	/// Load history for the previously selected period, using the provided filters
	func loadTransactionsWithFilters(_ filters: [TransactionFilter], state: inout State) -> Effect<Action> {
		guard filters != state.loading.filters else { return .none }
		state.sections = []
		state.loading = state.loading.withNewFilters(filters)
		return loadTransactionsForMonth(state.currentMonth, state: &state)
	}

	/// Load history for the provided month, keeping the same period and filters
	func loadTransactionsForMonth(_ month: Date, state: inout State) -> Effect<Action> {
		guard let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: month) else { return .none }
		if endOfMonth > state.fullPeriod.upperBound {
			state.sections = []
			state.loading = state.loading.withNewPivotDate(nil)
			return loadHistory(.down, scrollTarget: .latestTransaction, state: &state)
		} else {
			if state.sections.dateSpan?.contains(month ..< endOfMonth) == true {
				// We have already loaded all transactions for the chosen month
				state.setScrollTarget(.beforeDate(endOfMonth))
				return .none
			}
			state.sections = []
			state.loading = state.loading.withNewPivotDate(endOfMonth)
			return loadHistory(.down, scrollTarget: .beforeDate(endOfMonth), state: &state)
		}
	}

	/// Loads (more) transactions
	func loadTransactions(state: inout State) -> Effect<Action> {
		loadHistory(.down, state: &state)
	}

	func loadNewerTransactions(state: inout State) -> Effect<Action> {
		let scrollTarget: ScrollTarget = if let lastTransaction = state.sections.first?.transactions.first?.id {
			.transaction(lastTransaction)
		} else {
			.beforeDate(state.currentMonth)
		}
		return loadHistory(.up, scrollTarget: scrollTarget, state: &state)
	}

	/// Makes the TransactionHitosryRequest. **NB: don't call this directly**, instead use the specialised functions like `loadHistoryForMonth`
	func loadHistory(_ direction: Direction, scrollTarget: ScrollTarget? = nil, state: inout State) -> Effect<Action> {
		guard let parameters = state.requestParameters(for: direction) else { return .none }
		let cursor = state.loading[cursor: direction]
		guard !state.loading.isLoading, cursor != .loadedAll else { return .none }

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
			loggerGlobal.error("Received obsolete Transaction History response, should not be possible")
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

	var shouldAlsoLoadUpwards: Bool {
		guard let upwardsPeriod = requestParameters(for: .up)?.period else { return false }
		guard let lastLoaded = sections.dateSpan?.upperBound else { return true }
		return !upwardsPeriod.contains(lastLoaded)
	}

	mutating func setScrollTarget(_ scrollTarget: TransactionHistory.ScrollTarget?) {
		guard let scrollTarget else {
			self.scrollTarget = .updated(nil)
			return
		}

		func scrollToLatest() {
			guard let lastSection = sections.first, let lastTransaction = lastSection.transactions.first else { return }
			self.currentMonth = lastSection.month
			self.scrollTarget = .updated(lastTransaction.id)
		}

		switch scrollTarget {
		case let .transaction(txID):
			self.scrollTarget = .updated(txID)
		case let .beforeDate(date):
			if let lastSectionInMonth = sections.first(where: { $0.day < date }), let lastTransaction = lastSectionInMonth.transactions.first {
				self.currentMonth = lastSectionInMonth.month
				self.scrollTarget = .updated(lastTransaction.id)
			} else {
				scrollToLatest()
			}
		case .latestTransaction:
			scrollToLatest()
		}
	}

	func requestParameters(for direction: TransactionHistory.Direction) -> TransactionHistoryRequest.Parameters? {
		guard let period = period(for: direction), !period.isEmpty else { return nil }
		return .init(
			period: period,
			filters: loading.filters,
			direction: direction
		)
	}

	private func period(for direction: TransactionHistory.Direction) -> AnyRange<Date>? {
		guard !fullPeriod.isEmpty else { return nil }
		// Note that pivotDate == nil means that we are loading right up to the present
		switch direction {
		case .down:
			return .init(lowerBound: fullPeriod.lowerBound, upperBound: loading.pivotDate)
		case .up:
			if let pivotDate = loading.pivotDate {
				return .init(lowerBound: pivotDate)
			} else {
				// The up direction does not make sense
				return nil
			}
		}
	}
}

extension TransactionHistory.State.Loading {
	func withNewPivotDate(_ newPivotDate: Date?) -> Self {
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
				self[id: sectionID] = .init(day: day, month: month, transactions: transactions.asIdentified())
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

extension IdentifiedArrayOf<DateRangeItem> {
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
				date.formatted(.dateTime.month(.abbreviated))
			} else {
				date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
			}
		}

		self = zip(monthStarts, monthStarts.dropFirst())
			.map { start, end in
				.init(
					caption: caption(date: start),
					startDate: start,
					endDate: end
				)
			}
			.asIdentified()
	}
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
