import Foundation

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
	}
}

// MARK: - CreateAccount.Action.InternalAction.UserAction
public extension CreateAccount.Action.InternalAction {
	enum UserAction: Equatable {
		case closeButtonTapped
		case accountNameChanged(String)
	}
}

// MARK: - CreateAccount.Action.CoordinatingAction
public extension CreateAccount.Action {
	enum CoordinatingAction: Equatable {
		case dismissCreateAccount
	}
}
