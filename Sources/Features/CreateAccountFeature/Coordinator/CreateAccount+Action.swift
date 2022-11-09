import ComposableArchitecture
import Profile

// MARK: - CreateAccount.Action
public extension CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateAccount.Action.ViewAction
public extension CreateAccount.Action {
	enum ViewAction: Equatable {
		case viewAppeared
		case closeButtonTapped
		case createAccountButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(CreateAccount.State.Field?)
	}
}

// MARK: - CreateAccount.Action.InternalAction
public extension CreateAccount.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreateAccount.Action.InternalAction.SystemAction
public extension CreateAccount.Action.InternalAction {
	enum SystemAction: Equatable {
		case focusTextField(CreateAccount.State.Field?)
		case createdNewAccountResult(TaskResult<OnNetwork.Account>)
	}
}

// MARK: - CreateAccount.Action.DelegateAction
public extension CreateAccount.Action {
	enum DelegateAction: Equatable {
		case dismissCreateAccount
		case createdNewAccount(OnNetwork.Account)
		case failedToCreateNewAccount(reason: String)
	}
}
