import Foundation

public extension AccountDetails {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AccountDetails.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AccountDetails.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountDetails
	}
}

public extension AccountDetails.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountDetails
	}
}
