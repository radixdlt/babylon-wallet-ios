import Collections
import ComposableArchitecture
import NonEmpty
import Profile

// MARK: AccountList.State
public extension AccountList {
	// MARK: State
	struct State: Equatable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>
		public var alert: AlertState<Action.ViewAction>?

		public init(
			accounts: IdentifiedArrayOf<AccountList.Row.State>,
			alert: AlertState<Action.ViewAction>? = nil
		) {
			self.accounts = accounts
			self.alert = alert
		}
	}
}

// MARK: - Convenience
public extension AccountList.State {
	init(nonEmptyOrderedSetOfAccounts accounts: NonEmpty<OrderedSet<OnNetwork.Account>>) {
		self.init(
			accounts: .init(uniqueElements: accounts.rawValue.elements.map(AccountList.Row.State.init(account:)))
		)
	}
}

#if DEBUG
public extension Array where Element == AccountList.Row.State {
//	static let placeholder: Self = [.checking, .savings, .shared, .family, .dummy1, .dummy2, .dummy3]
	static let placeholder: Self = []
}

public extension IdentifiedArray where Element == AccountList.Row.State, ID == AccountList.Row.State.ID {
	static let placeholder: Self = .init(uniqueElements: Array<AccountList.Row.State>.placeholder)
}

#endif
