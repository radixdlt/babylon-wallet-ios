import ComposableArchitecture

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let periods: [DateRangeItem]

		var selectedPeriod: DateRangeItem.ID

		var sections: IdentifiedArrayOf<TransactionSection>
		var loadedPeriods: Set<Date> = []

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
		case closeTapped
		case selectedPeriod(DateRangeItem.ID)
	}

	public enum InternalAction: Sendable, Hashable {
		case updateTransactions([TransactionHistoryItem])
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.transactionHistoryClient) var transactionHistoryClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selectedPeriod(period):
			state.selectedPeriod = period
			return .run { [account = state.account.address] send in

				let account = try AccountAddress(validatingAddress: "account_rdx128z7rwu87lckvjd43rnw0jh3uczefahtmfuu5y9syqrwsjpxz8hz3l")

				let transactions = try await transactionHistoryClient.getTransactionHistory(account, nil)
				await send(.internal(.updateTransactions(transactions.items)))
			}

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

	// Helper methods
}

extension TransactionHistory.State {
	///  Presupposes that transactions are loaded in chunks of full months
	mutating func updateTransactions(_ transactions: [TransactionHistoryItem]) {
		let newSections = transactions.inSections
		var sections = self.sections
		sections.append(contentsOf: newSections)
		sections.sort(by: \.day)
		self.sections = sections
		loadedPeriods.append(contentsOf: newSections.map(\.month))
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

// TEMPORARY: MOCK

// extension TransactionHistory.State {
//	init(account: Profile.Network.Account) {
//		self.init(
//			account: account,
//			sections: (1 ... 5).map { _ in .mock }
//		)
//	}
// }
//
// extension TransactionHistory.State.TransactionSection {
//	static var mock: Self {
//		let calendar = Calendar.current
//		let time = Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000))
//		return .init(
//			day: calendar.startOfDay(for: time),
//			month: calendar.startOfMonth(for: time),
//			transactions: (1 ... 5).map { _ in .mock }
//		)
//	}
// }
//
// extension GatewayAPIClient.TransactionHistoryItem {
//	static var mock: Self {
//		.init(
//			time: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
//			message: Bool.random() ? "This is a message" : nil,
//			actions: [],
//			manifestType: .random()
//		)
//	}
// }
//
extension TransactionHistoryItem.ManifestType {
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

//
// extension GatewayAPIClient.TransactionHistoryItem.Action {
//	static func random() -> Self {
//		switch Int.random(in: 0 ... 2) {
//		case 0: .deposit
//		case 1: .withdrawal
//		default: .settings
//		}
//	}
// }
