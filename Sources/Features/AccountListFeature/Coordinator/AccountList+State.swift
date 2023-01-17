import FeaturePrelude

// MARK: - AccountList.State
public extension AccountList {
	// MARK: State
	struct State: Sendable, Equatable {
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
	static let previewValue: Self = []
}

public extension IdentifiedArray where Element == AccountList.Row.State, ID == AccountList.Row.State.ID {
	static let previewValue: Self = .init(uniqueElements: Array<AccountList.Row.State>.previewValue)
}

#endif
