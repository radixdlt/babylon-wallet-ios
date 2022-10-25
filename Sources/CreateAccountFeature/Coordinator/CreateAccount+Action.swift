import ComposableArchitecture
import Profile

// MARK: - CreateAccount.Action
public extension CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - CreateAccount.Action.InternalAction
public extension CreateAccount.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - CreateAccount.Action.InternalAction.UserAction
public extension CreateAccount.Action.InternalAction {
	enum UserAction: Equatable {
		case dismiss
		case createAccount
		case textFieldDidChange(String)
		case textFieldDidFocus
	}
}

// MARK: - CreateAccount.Action.InternalAction.SystemAction
public extension CreateAccount.Action.InternalAction {
	enum SystemAction: Equatable {
		case viewDidAppear
		case focusTextField
		case createdNewAccountResult(TaskResult<OnNetwork.Account>)
	}
}

// MARK: - CreateAccount.Action.CoordinatingAction
public extension CreateAccount.Action {
	enum CoordinatingAction: Equatable {
		case dismissCreateAccount
		case createdNewAccount(OnNetwork.Account)
		case failedToCreateNewAccount(reason: String)
	}
}
