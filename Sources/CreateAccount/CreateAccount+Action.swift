import Foundation

public extension CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
	}
}

public extension CreateAccount.Action {
	enum CoordinatingAction: Equatable {
		case dismissCreateAccount
	}
}
