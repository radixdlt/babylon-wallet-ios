import Foundation

public extension Home.AccountDetails {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.AccountDetails.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.AccountDetails.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountDetails
	}
}

public extension Home.AccountDetails.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountDetails
	}
}
