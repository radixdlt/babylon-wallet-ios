import ComposableArchitecture

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let periods: [DateRangeItem]

		var selectedPeriod: DateRangeItem.ID

		let sections: [TransactionSection]

		init(account: Profile.Network.Account, sections: [TransactionSection]) {
			self.account = account
			self.periods = try! .init(months: 7)
			self.selectedPeriod = periods[0].id
			self.sections = sections
		}

		public struct TransactionSection: Sendable, Hashable, Identifiable {
			public var id: Date { date }
			let date: Date
			let transactions: [Transaction]
		}

		public struct Transaction: Sendable, Hashable {
			let time: Date
			let message: String?
			let actions: [Action]
			let manifestType: ManifestType

			enum Action {
				case deposit
				case withdrawal
				case settings
			}

			enum ManifestType {
				case transfer
				case contribute
				case claim
				case depositSettings
				case other
			}
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case closeTapped
		case selectedPeriod(DateRangeItem.ID)
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selectedPeriod(period):
			state.selectedPeriod = period
			return .none

		case .closeTapped:
			return .run { _ in await dismiss() }
		}
	}

	// Helper methods
}

// MARK: - FailedToCalculateDate
struct FailedToCalculateDate: Error {}

extension [DateRangeItem] {
	init(months: Int, upTo now: Date = .now) throws {
		let calendar: Calendar = .current
		let monthStart = try calendar.startOfMonth(now)
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

	func startOfMonth(_ date: Date) throws -> Date {
		var components = dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
		components.day = 1
		components.hour = 0
		components.minute = 0
		components.second = 0
		components.nanosecond = 0

		guard let start = self.date(from: components) else {
			struct FailedToFindMonthStart: Error {
				let date: Date
			}
			throw FailedToFindMonthStart(date: date)
		}

		return start
	}
}

// TEMPORARY: MOCK

extension TransactionHistory.State {
	init(account: Profile.Network.Account) {
		self.init(
			account: account,
			sections: (1 ... 5).map { _ in .mock }
		)
	}
}

extension StoreOf<TransactionHistory> {
	static func transactionHistory(account: Profile.Network.Account) -> Store {
		Store(initialState: State(account: account)) {
			TransactionHistory()
		}
	}
}

extension TransactionHistory.State.TransactionSection {
	static var mock: Self {
		.init(
			date: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
			transactions: (1 ... 5).map { _ in .mock }
		)
	}
}

extension TransactionHistory.State.Transaction {
	static var mock: Self {
		.init(
			time: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
			message: Bool.random() ? "This is a message" : nil,
			actions: [],
			manifestType: .random()
		)
	}
}

extension TransactionHistory.State.Transaction.ManifestType {
	static func random() -> Self {
		switch Int.random(in: 0 ... 4) {
		case 0: .transfer
		case 1: .contribute
		case 2: .claim
		case 3: .depositSettings
		default: .other
		}
	}
}

extension TransactionHistory.State.Transaction.Action {
	static func random() -> Self {
		switch Int.random(in: 0 ... 2) {
		case 0: .deposit
		case 1: .withdrawal
		default: .settings
		}
	}
}
