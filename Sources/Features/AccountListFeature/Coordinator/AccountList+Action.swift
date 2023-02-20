import FeaturePrelude

// MARK: - AccountList.Action
extension AccountList {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountList.Action.ChildAction
extension AccountList.Action {
	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}
}

// MARK: - AccountList.Action.ViewAction
extension AccountList.Action {
	public enum ViewAction: Sendable, Equatable {
		case viewAppeared
	}
}

// MARK: - AccountList.Action.InternalAction
extension AccountList.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountList.Action.InternalAction.SystemAction
extension AccountList.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - AccountList.Action.DelegateAction
extension AccountList.Action {
	public enum DelegateAction: Sendable, Equatable {
		case displayAccountDetails(AccountList.Row.State)
		case fetchPortfolioForAccounts
	}
}
