import ComposableArchitecture
import Foundation

// MARK: - AccountList
/// Namespace for AccountListFeature
public extension Home {
	enum AccountList {}
}

public extension Home.AccountList {
	// MARK: State
	struct State: Equatable {
		public var accounts: IdentifiedArrayOf<Home.AccountRow.State>
		public var alert: AlertState<Action>?

		public init(
			accounts: IdentifiedArrayOf<Home.AccountRow.State> = [],
			alert: AlertState<Action>? = nil
		) {
			self.accounts = accounts
			self.alert = alert
		}
	}
}

#if DEBUG
public extension Array where Element == Home.AccountRow.State {
	static let placeholder: Self = [.checking, .savings, .shared]
}

public extension IdentifiedArray where Element == Home.AccountRow.State, ID == Home.AccountRow.State.ID {
	static let placeholder: Self = .init(uniqueElements: Array<Home.AccountRow.State>.placeholder)
}

public extension Home.AccountRow.State {
	static let checking: Self = .init(
		address: UUID().uuidString,
		name: "Checking",
		tokens: []
	)

	static let savings: Self = .init(
		address: UUID().uuidString,
		name: "Savings",
		tokens: []
	)

	static let shared: Self = .init(
		address: UUID().uuidString,
		name: "Shared",
		tokens: []
	)
}
#endif
