import Foundation

public extension AccountDetails.Transfer {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AccountDetails.Transfer.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension AccountDetails.Transfer.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissTransfer
	}
}

public extension AccountDetails.Transfer.Action {
	enum CoordinatingAction: Equatable {
		case dismissTransfer
	}
}
