import FeaturePrelude
import LocalAuthenticationClient

// MARK: - CreateAccount.Action
public extension CreateAccount {
	// MARK: Action
	enum Action: Sendable, Equatable {
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateAccount.Action.ViewAction
public extension CreateAccount.Action {
	enum ViewAction: Sendable, Equatable {
		case viewAppeared
		case closeButtonTapped
		case createAccountButtonTapped
		case textFieldChanged(String)
		case textFieldFocused(CreateAccount.State.Field?)
	}
}

// MARK: - CreateAccount.Action.InternalAction
public extension CreateAccount.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CreateAccount.Action.InternalAction.SystemAction
public extension CreateAccount.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case focusTextField(CreateAccount.State.Field?)
		case createdNewProfileResult(TaskResult<Profile>)
		case createdNewAccountResult(TaskResult<OnNetwork.Account>)
		case injectProfileIntoProfileClientResult(TaskResult<Profile>)
		case loadAccountResult(TaskResult<OnNetwork.Account>)
	}
}

// MARK: - CreateAccount.Action.DelegateAction
public extension CreateAccount.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissCreateAccount
		case createdNewAccount(account: OnNetwork.Account, isFirstAccount: Bool)
	}
}
