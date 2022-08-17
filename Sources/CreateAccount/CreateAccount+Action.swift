import Foundation

public extension CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension CreateAccount.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension CreateAccount.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension CreateAccount.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension CreateAccount.Action {
	enum CoordinatingAction: Equatable {}
}
