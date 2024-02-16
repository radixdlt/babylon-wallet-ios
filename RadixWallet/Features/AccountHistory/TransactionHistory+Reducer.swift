import ComposableArchitecture

/*
 public private(set) var stateVersion: Int64
 public private(set) var epoch: Int64
 public private(set) var round: Int64
 public private(set) var roundTimestamp: String
 public private(set) var transactionStatus: TransactionStatus
 /** Bech32m-encoded hash. */
 public private(set) var payloadHash: String?
 /** Bech32m-encoded hash. */
 public private(set) var intentHash: String?
 /** String-encoded decimal representing the amount of a related fungible resource. */
 public private(set) var feePaid: String?
 public private(set) var affectedGlobalEntities: [String]?
 public private(set) var confirmedAt: Date?
 public private(set) var errorMessage: String?
 /** Hex-encoded binary blob. */
 public private(set) var rawHex: String?
 public private(set) var receipt: TransactionReceipt?
 /** The optional transaction message. This type is defined in the Core API as `TransactionMessage`. See the Core API documentation for more details.  */
 public private(set) var message: AnyCodable?
 public private(set) var balanceChanges: TransactionBalanceChanges?
 */

extension [GatewayAPI.CommittedTransactionInfo] {
	/// The day of the transaction, as a date with hours, minutes, seconds and nanoseconds set to 0
	var sections: [TransactionHistory.State.TransactionSection] {
		let calendar: Calendar = .current
		let groupedTransactions = Dictionary(grouping: self) { $0.confirmedAt.map(calendar.startOfDay) }
		let days = groupedTransactions.keys.compacted().sorted()

		print("••••• \(self.count)")

		return days.compactMap { day -> TransactionHistory.State.TransactionSection? in
			guard let transactionInfos = groupedTransactions[day] else { return nil }
			print("•••••• \(day.formatted(date: .abbreviated, time: .shortened)) :: \(transactionInfos.count)")
			return .init(day: day, transactions: transactionInfos.compactMap(\.transaction))
		}
	}
}

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

		var sections: [TransactionSection]

		init(account: Profile.Network.Account, sections: [TransactionSection] = []) {
			self.account = account
			self.periods = try! .init(months: 7)
			self.selectedPeriod = periods[0].id
			self.sections = sections
		}

		public struct TransactionSection: Sendable, Hashable, Identifiable {
			public var id: Date { day }
			/// The day, in the form of a `Date` with all time components set to 0
			let day: Date
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

	public enum InternalAction: Sendable, Hashable {
		case updateSections([State.TransactionSection])
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selectedPeriod(period):
			state.selectedPeriod = period

			let request = GatewayAPI.StreamTransactionsRequest(
				//				atLedgerState: .some(.),
//				fromLedgerState: <#T##GatewayAPI.LedgerStateSelector?#>,
//				cursor: <#T##String?#>,
				limitPerPage: 100,
//				kindFilter: <#T##GatewayAPI.StreamTransactionsRequest.KindFilter?#>,
				manifestAccountsWithdrawnFromFilter: [state.account.address.address],
//				manifestAccountsDepositedIntoFilter: [state.account.address.address]
//				manifestResourcesFilter: <#T##[String]?#>,
//				affectedGlobalEntitiesFilter: <#T##[String]?#>,
//				eventsFilter: <#T##[GatewayAPI.StreamTransactionsRequestEventFilterItem]?#>,
//				order: <#T##GatewayAPI.StreamTransactionsRequest.Order?#>,
				optIns: .init(affectedGlobalEntities: true, balanceChanges: true)
			)

			return .run { send in
				let response = try await gatewayAPIClient.transactionHistory(request)
				print("•••••• updateSections \(response.totalCount) \(response.items.count)")
				await send(.internal(.updateSections(response.items.sections)))
			}

		case .closeTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updateSections(sections):
			state.sections = sections
			return .none
		}
	}

	// Helper methods
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
