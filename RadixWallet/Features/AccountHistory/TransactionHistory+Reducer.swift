import ComposableArchitecture

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let periods: [DateRangeItem]

		var activeFilters: IdentifiedArrayOf<TransactionFilters.State.Filter> = []

		var selectedPeriod: DateRangeItem.ID

		var sections: IdentifiedArrayOf<TransactionSection>
		var loadedPeriods: Set<Date> = []

		@PresentationState
		public var destination: Destination.State?

		init(account: Profile.Network.Account, sections: [TransactionSection] = []) {
			self.account = account
			self.periods = try! .init(months: 7)
			self.selectedPeriod = periods[0].id
			self.sections = sections.asIdentifiable()
		}

		public struct TransactionSection: Sendable, Hashable, Identifiable {
			public var id: Date { day }
			/// The day, in the form of a `Date` with all time components set to 0
			let day: Date
			/// The month, in the form of a `Date` with all time components set to 0 and the day set to 1
			let month: Date
			var transactions: [TransactionHistoryItem]
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case onAppear
		case selectedPeriod(DateRangeItem.ID)
		case filtersTapped
		case removeFilterTapped(TransactionFilters.State.Filter.ID)
		case closeTapped
	}

	public enum InternalAction: Sendable, Hashable {
		case updateTransactions([TransactionHistoryItem])
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case filters(TransactionFilters.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case filters(TransactionFilters.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.filters, action: \.filters) {
				TransactionFilters()
			}
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.transactionHistoryClient) var transactionHistoryClient

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
			return loadSelectedPeriod(state: &state)
		case let .selectedPeriod(period):
			state.selectedPeriod = period
			return loadSelectedPeriod(state: &state)

		case .filtersTapped:
			state.destination = .filters(.init(assets: [], activeFilters: state.activeFilters.map(\.id)))
			return .none

		case let .removeFilterTapped(id):
			state.activeFilters.remove(id: id)
			return .none

		case .closeTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updateTransactions(transactions):
			state.updateTransactions(transactions)
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

	// Helper methods

	func loadSelectedPeriod(state: inout State) -> Effect<Action> {
		guard let range = state.periods.first(where: { $0.id == state.selectedPeriod })?.range.clamped else {
			return .none
		}

		return .run { [account = state.account.address] send in
			let transactions = try await transactionHistoryClient.getTransactionHistory(account, range, String?.none)
			await send(.internal(.updateTransactions(transactions.items)))
		}
	}
}

private extension Range<Date> {
	var clamped: Range? {
		let now: Date = .now
		guard lowerBound < now else { return nil }
		return lowerBound ..< Swift.min(upperBound, now.addingTimeInterval(0)) // FIXME: Figure out end date
	}
}

extension TransactionHistory.State {
	///  Presupposes that transactions are loaded in chunks of full months
	mutating func updateTransactions(_ transactions: [TransactionHistoryItem]) {
//		let newSections = transactions.inSections
//		var sections = self.sections
//		sections.append(contentsOf: newSections)
//		sections.sort(by: \.day)
//		self.sections = sections
//		loadedPeriods.append(contentsOf: newSections.map(\.month))

		sections.removeAll()
		sections.append(contentsOf: transactions.inSections)
		sections.sort(by: \.day)
		loadedPeriods.append(contentsOf: sections.map(\.month))
	}

	mutating func clearSections() {
		sections.removeAll(keepingCapacity: true)
		loadedPeriods.removeAll(keepingCapacity: true)
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
	init(months: Int, upTo now: Date = .now) throws {
		let calendar: Calendar = .current
		let monthStart = calendar.startOfMonth(for: now)
		let dates = ((1 - months) ... 1).compactMap { calendar.date(byAdding: .month, value: $0, to: monthStart) }

		guard dates.count == months + 1 else {
			throw FailedToCalculateDate()
		}

		func caption(date: Date) -> String {
			if calendar.areSameYear(date, now) {
				Self.sameYearFormatter.string(from: date)
			} else {
				Self.otherYearFormatter.string(from: date)
			}
		}

		self = zip(dates, dates.dropFirst()).map { start, end in
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
