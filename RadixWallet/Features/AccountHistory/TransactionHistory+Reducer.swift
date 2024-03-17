import ComposableArchitecture

private extension Date {
	// September 28th, 2023, at 9.30 PM UTC
	static let babylonLaunch = Date(timeIntervalSince1970: 1_695_893_400)
}

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public enum Direction: Sendable {
		case up
		case down
	}

	public struct State: Sendable, Hashable {
		let availableMonths: [DateRangeItem]

		let account: Profile.Network.Account

		let portfolio: OnLedgerEntity.Account

		var resources: IdentifiedArrayOf<OnLedgerEntity.Resource> = []

		var activeFilters: IdentifiedArrayOf<TransactionHistoryFilters.State.Filter> = []

		var sections: IdentifiedArrayOf<TransactionSection> = []

		/// The currently selected month
		var currentMonth: DateRangeItem.ID

		/// Values related to loading. Note that `parameters` are set **when receiving the response**
		var loading: Loading = .init(parameters: .init(period: Date.now ..< Date.now))

		/// Workaround, TCA sends the sectionDisappeared after we dismiss, causing a run-time warning
		var didDismiss: Bool = false

		struct Loading: Hashable, Sendable {
			let parameters: TransactionHistoryParameters
			var isLoading: Bool = false
			var nextCursor: String? = nil
			var didLoadFully: Bool = false
		}

		@PresentationState
		public var destination: Destination.State?

		init(account: Profile.Network.Account) throws {
			@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

			guard let portfolio = accountPortfoliosClient.portfolios().first(where: { $0.account.address == account.address }) else {
				struct MissingPortfolioError: Error { let account: AccountAddress }
				throw MissingPortfolioError(account: account.accountAddress)
			}

			self.availableMonths = try .from(.babylonLaunch)
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
		case transactionsTableAction(TransactionsTableView.Action)
		case closeTapped
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
			return loadHistory(period: .babylonLaunch ..< .now, state: &state)

		case let .selectedMonth(month):
			let calendar: Calendar = .current
			guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: month) else { return .none }
			let period: Range<Date> = .babylonLaunch ..< min(endOfMonth, .now)
			state.currentMonth = month
			print("• selectedMonth: LOAD period")
			return loadHistory(period: period, state: &state)

		case .filtersTapped:

			// FIXME: GK REMOVE
			guard !state.loading.isLoading else { return .none }
			switch state.loading.parameters.direction {
			case .down:
				// If we are at the end of the period, we can't load more
				guard state.currentMonth != state.availableMonths.last?.id else { print("•• can't load later tx"); return .none }
				guard let loadedRange = state.loadedRange else { return .none }
				print("• filtersTapped: LOAD period upwards")
				return loadHistory(period: loadedRange.upperBound ..< .now, direction: .up, state: &state)
			case .up:
				print("• filtersTapped: LOAD more upwards")
				return loadMoreHistory(state: &state)
			}

//			state.destination = .filters(.init(portfolio: state.portfolio, filters: state.activeFilters.map(\.id)))
//			return .none

		case let .filterCrossTapped(id):
			state.activeFilters.remove(id: id)
			return loadHistory(filters: state.activeFilters.map(\.id), state: &state)

		case .closeTapped:
			state.didDismiss = true
			return .run { _ in await dismiss() }

		case let .transactionsTableAction(action):
			switch action {
			case .pulledDown:
				print("• ACTION scrolledPastTop")
//				guard !state.loading.isLoading else { return .none }
//				switch state.loading.parameters.direction {
//				case .down:
//					// If we are at the end of the period, we can't load more
//					guard state.currentMonth != state.availableMonths.last?.id else { print("•• can't load later tx"); return .none }
//					guard let loadedRange = state.loadedRange else { return .none }
//					print("• filtersTapped: LOAD period upwards")
//					return loadHistory(period: loadedRange.upperBound ..< .now, direction: .up, state: &state)
//				case .up:
//					print("• filtersTapped: LOAD more upwards")
//					return loadMoreHistory(state: &state)
//				}

			case .nearingTop:
				print("• ACTION nearingTop")
				guard !state.loading.isLoading else { return .none }
				switch state.loading.parameters.direction {
				case .down:
					// If we are at the end of the period, we can't load more
					guard state.currentMonth != state.availableMonths.last?.id else { print("•• can't load later tx"); return .none }
					guard let loadedRange = state.loadedRange else { return .none }
					print("• filtersTapped: LOAD period upwards")
					return loadHistory(period: loadedRange.upperBound ..< .now, direction: .up, state: &state)
				case .up:
					print("• filtersTapped: LOAD more upwards")
					return loadMoreHistory(state: &state)
				}

			case .nearingBottom, .reachedBottom:
				print("• ACTION nearingBottom/reachedBottom: LOAD more")
				return loadMoreHistory(state: &state)

			case let .monthChanged(month):
				state.currentMonth = month

			case let .transactionTapped(txid):
				let path = "transaction/\(txid.asStr())/summary"
				let url = Radix.Dashboard.dashboard(forNetworkID: state.account.networkID).url.appending(path: path)
				return .run { _ in
					await openURL(url)
				}
			}

			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedHistory(history):
			loadedHistory(history, state: &state)
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
		loadHistory(filters: state.activeFilters.map(\.id), state: &state)
	}

	// Helper methods

	/// Load history for the given period, using existing filters
	func loadHistory(period: Range<Date>, direction: Direction = .down, state: inout State) -> Effect<Action> {
		var parameters = state.loading.parameters
		parameters.period = period
		parameters.direction = direction
		return loadHistory(parameters: parameters, state: &state)
	}

	/// Load history for the current period using the provided filters
	func loadHistory(filters: [TransactionFilter], state: inout State) -> Effect<Action> {
		var parameters = state.loading.parameters
		parameters.filters = filters
		return loadHistory(parameters: parameters, state: &state)
	}

	/// Load more history for the same period, using the existing filters
	func loadMoreHistory(state: inout State) -> Effect<Action> {
		loadHistory(parameters: state.loading.parameters, state: &state)
	}

	/// Load history using the provided parameters, should not be used directly
	func loadHistory(parameters: TransactionHistoryParameters, state: inout State) -> Effect<Action> {
		if state.loading.isLoading { return .none }

		if state.loading.didLoadFully, state.loading.parameters.covers(parameters) { print("•• ALREADY LOADED"); return .none }

		print("•• LOAD HISTORY: \(parameters != state.loading.parameters ? "new parameters" : "same params")")

		if parameters != state.loading.parameters {
			state.loading.nextCursor = nil
		}

		state.loading.isLoading = true

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
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func loadedHistory(_ response: TransactionHistoryResponse, state: inout State) {
		state.resources.append(contentsOf: response.resources)

		func shouldPrependWithOverlap() -> Int? {
			guard !state.sections.isEmpty else { return nil }
			guard state.loading.parameters.direction == .down, response.parameters.direction == .up else { return nil }
			let overlap = state.sections.allTransactions.prefixOverlappingSuffix(of: response.items.map(\.id))
			guard overlap > 0 else { return nil }
			return overlap
		}

		if response.parameters == state.loading.parameters {
			print("•• LOADED \(response.items.count) same params")
			// We loaded more from the same range
			state.loading.nextCursor = response.nextCursor
			if response.nextCursor == nil {
				state.loading.didLoadFully = true
			}

			state.sections.addItems(response.items, direction: response.parameters.direction)
		} else if let overlap = shouldPrependWithOverlap() {
			print("•• LOADED \(response.items.count) overlap: \(overlap)")
			// Switched from down to up, prepend new data to existing, but with some overlap
			state.loading = .init(parameters: response.parameters, nextCursor: response.nextCursor)
			state.sections.insertItemsAtStart(response.items, withOverlap: overlap)
		} else {
			print("•• LOADED \(response.items.count) new params")
			state.loading = .init(parameters: response.parameters, nextCursor: response.nextCursor)
			state.sections.replaceItems(response.items)
		}

		state.loading.isLoading = false
	}
}

// MARK: - TransactionHistory.TransactionSection + CustomStringConvertible
extension TransactionHistory.TransactionSection: CustomStringConvertible {
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
	var debugString: String {
		"\(lowerBound.formatted(date: .abbreviated, time: .omitted)) -- \(upperBound.formatted(date: .abbreviated, time: .omitted))"
	}
}

extension IdentifiedArrayOf<TransactionHistory.TransactionSection> {
	mutating func insertItemsAtStart(_ items: some Collection<TransactionHistoryItem>, withOverlap overlap: Int) {
		addItems(items.dropLast(overlap), direction: .up)
	}

	mutating func addItems(_ items: some Collection<TransactionHistoryItem>, direction: TransactionHistory.Direction) {
		let newSections = items.inSections

		switch direction {
		case .down:
			for newSection in newSections {
				if last?.id == newSection.id {
					self[id: newSection.id]?.transactions.append(contentsOf: newSection.transactions)
				} else {
					append(newSection)
				}
			}
			print("•• inserted \(items.count) after -> \(allTransactions.count)")

		case .up:
			for newSection in newSections.reversed() {
				if first?.id == newSection.id {
					self[id: newSection.id]?.transactions.insert(contentsOf: newSection.transactions, at: 0)
				} else {
					insert(newSection, at: 0)
				}
			}

			print("•• inserted \(items.count) before -> \(allTransactions.count)")
		}
	}

	mutating func replaceItems(_ items: some Collection<TransactionHistoryItem>) {
		self = items.inSections.asIdentifiable()
	}
}

extension Collection<TransactionHistoryItem> {
	var inSections: [TransactionHistory.TransactionSection] {
		let calendar: Calendar = .current

		var result: [TransactionHistory.TransactionSection] = []

		for transaction in self {
			let day = calendar.startOfDay(for: transaction.time)
			if let lastSection = result.last, lastSection.day == day {
				result[result.endIndex - 1].transactions.append(transaction)
			} else {
				result.append(
					.init(
						day: day,
						month: calendar.startOfMonth(for: day),
						transactions: [transaction]
					)
				)
			}
		}

		return result
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
