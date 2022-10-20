import ComposableArchitecture
import Profile

// MARK: - AccountList
/// Namespace for AccountListFeature
public enum AccountList {}

// MARK: AccountList.State
public extension AccountList {
	// MARK: State
	struct State: Equatable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>
		public var alert: AlertState<Action>?

		public init(
			accounts: IdentifiedArrayOf<AccountList.Row.State>,
			alert: AlertState<Action>? = nil
		) {
			self.accounts = accounts
			self.alert = alert
		}
	}
}

// MARK: - Convenience
public extension AccountList.State {
	init(just accounts: [OnNetwork.Account]) {
		self.init(
			accounts: .init(uniqueElements: accounts.map(AccountList.Row.State.init(account:)))
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
