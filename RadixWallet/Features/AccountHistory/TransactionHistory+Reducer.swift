import ComposableArchitecture

extension GatewayAPI.CommittedTransactionInfo {
	/// The day of the transaction, as a date with hours, minutes, seconds and nanoseconds set to 0
	var transaction: TransactionHistory.State.Transaction? {
		guard let time = confirmedAt else { return nil }

//		print("  •• \(time.formatted()): \(affectedGlobalEntities ?? [])")

		if let balanceChanges {
			for change in balanceChanges.fungibleBalanceChanges {
				print("    • \(change.balanceChange) of \(change.resourceAddress.formatted(.default)) for \(change.entityAddress.formatted(.default))")
			}
		} else {
			print("    • No balance change")
		}

		return .init(
			time: time,
			message: "----",
			actions: [],
			manifestType: .random()
		)
	}
}

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let periods: [DateRangeItem]

		var selectedPeriod: DateRangeItem.ID

		var sections: IdentifiedArrayOf<TransactionSection>
		var monthsLoaded: Set<Date> = []

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
			var transactions: [GatewayAPIClient.TransactionHistoryItem]
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case closeTapped
		case selectedPeriod(DateRangeItem.ID)
	}

	public enum InternalAction: Sendable, Hashable {
		case updateSections([State.TransactionSection])
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selectedPeriod(period):
			state.selectedPeriod = period
			return .run { [account = state.account.address] _ in
				let sections = try await gatewayAPIClient.transactionHistory(account: account)
				print("•••••• updateSections \(sections.count)")
//				await send(.internal(.updateSections(sections)))
			}

		case .closeTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updateSections(sections):
//			state.sections = sections
			.none
		}
	}

	// Helper methods
}

extension TransactionHistory.State {
	mutating func updateSections(_ transactions: [TransactionSection.Transaction]) {
		let newSections = [TransactionSection](grouping: transactions)
		sections.append(contentsOf: newSections)
		monthsLoaded.append(contentsOf: newSections.map(\.month))
	}

	mutating func clearSections() {
		sections.removeAll(keepingCapacity: true)
		monthsLoaded.removeAll(keepingCapacity: true)
	}
}

extension IdentifiedArrayOf<TransactionHistory.State.TransactionSection> {
	init(grouping transactions: [GatewayAPIClient.TransactionHistoryItem]) {
		let calendar: Calendar = .current

		let sortedBackwards = transactions.sorted(by: \.time, >)
		var result: Self = []

		for transaction in sortedBackwards {
			let day = calendar.startOfDay(for: transaction.time)
			guard let month = try? calendar.startOfMonth(for: transaction.time) else { continue }

			if result[id: day] == nil {
				result[id: day] = .init(day: day, month: month, transactions: [transaction])
			} else {
				result[id: day]?.append(transaction)
			}
		}

		self = result
	}
}

extension [TransactionHistory.State.TransactionSection] {
	init(grouping transactions: [GatewayAPIClient.TransactionHistoryItem]) {
		let calendar: Calendar = .current

		let sortedBackwards = transactions.sorted(by: \.time, >)
		var result: Self = []

		for transaction in sortedBackwards {
			let day = calendar.startOfDay(for: transaction.time)
			guard let month = try? calendar.startOfMonth(for: transaction.time) else { continue }

			if result.last?.day == day {
				result[result.endIndex - 1].append(transaction)
			} else {
				result.append(.init(day: day, month: month, transactions: [transaction]))
			}
		}

		self = result
	}
}

extension TransactionHistory.State.TransactionSection {
	typealias Transaction = GatewayAPIClient.TransactionHistoryItem

	mutating func append(_ transaction: Transaction) {
		transactions.append(transaction)
	}
}

// MARK: - FailedToCalculateDate
struct FailedToCalculateDate: Error {}

extension [DateRangeItem] {
	init(months: Int, upTo now: Date = .now) throws {
		let calendar: Calendar = .current
		let monthStart = try calendar.startOfMonth(for: now)
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

	func startOfMonth(for date: Date) throws -> Date {
		var components = dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
		components.day = 1
		components.hour = 0
		components.minute = 0
		components.second = 0
		components.nanosecond = 0

		guard let start = self.date(from: components) else {
			struct FailedToFindStartOfMonth: Error {
				let date: Date
			}
			throw FailedToFindStartOfMonth(date: date)
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

extension TransactionHistory.State.TransactionSection {
	static var mock: Self {
		.init(
			day: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
			transactions: (1 ... 5).map { _ in .mock }
		)
	}
}

extension GatewayAPIClient.TransactionHistoryItem {
	static var mock: Self {
		.init(
			time: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
			message: Bool.random() ? "This is a message" : nil,
			actions: [],
			manifestType: .random()
		)
	}
}

extension GatewayAPIClient.TransactionHistoryItem.ManifestType {
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

extension GatewayAPIClient.TransactionHistoryItem.Action {
	static func random() -> Self {
		switch Int.random(in: 0 ... 2) {
		case 0: .deposit
		case 1: .withdrawal
		default: .settings
		}
	}
}
