import Foundation

public extension Home.CreateAccount {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
	}
}

public extension Home.CreateAccount.Action {
	enum CoordinatingAction: Equatable {
		case dismissCreateAccount
	}
}
