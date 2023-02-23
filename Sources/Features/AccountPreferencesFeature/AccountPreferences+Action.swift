import FeaturePrelude

// MARK: - AccountPreferences.Action
extension AccountPreferences {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AccountPreferences.Action.ViewAction
extension AccountPreferences.Action {
	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case closeButtonTapped
		case faucetButtonTapped
	}
}

// MARK: - AccountPreferences.Action.InternalAction
extension AccountPreferences.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AccountPreferences.Action.SystemAction
extension AccountPreferences.Action {
	public enum SystemAction: Sendable, Equatable {
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case refreshAccountCompleted
		case hideLoader
	}
}

// MARK: - AccountPreferences.Action.DelegateAction
extension AccountPreferences.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case refreshAccount(AccountAddress)
	}
}
