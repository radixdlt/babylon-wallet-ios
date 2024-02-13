import ComposableArchitecture

// MARK: - TransactionHistory
public struct TransactionHistory: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: Profile.Network.Account

		let sections: [TransferSection]

		public struct TransferSection: Sendable, Hashable, Identifiable {
			public var id: Date { date }
			let date: Date
			let transfers: [Transfer]
		}

		public struct Transfer: Sendable, Hashable {
			let string: String
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case closeTapped
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			.run { _ in await dismiss() }
		}
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

extension TransactionHistory.State.TransferSection {
	static var mock: Self {
		.init(
			date: Date(timeIntervalSince1970: 1000 * .random(in: 100 ... 100_000)),
			transfers: (1 ... 5).map { _ in .mock }
		)
	}
}

extension TransactionHistory.State.Transfer {
	static var mock: Self {
		.init(string: "Transfer " + String(Int.random(in: 100 ... 1000)))
	}
}
