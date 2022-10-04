import Foundation

// MARK: - CreateAccount.Action
public extension CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
	}
}

// MARK: - CreateAccount.Action.CoordinatingAction
public extension CreateAccount.Action {
	enum CoordinatingAction: Equatable {
		case dismissCreateAccount
	}
}
