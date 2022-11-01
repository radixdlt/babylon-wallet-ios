import Foundation

// MARK: - AccountDetails.Transfer.Action
public extension AccountDetails.Transfer {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AccountDetails.Transfer.Action.InternalAction
public extension AccountDetails.Transfer.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - AccountDetails.Transfer.Action.InternalAction.UserAction
public extension AccountDetails.Transfer.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissTransfer
	}
}

// MARK: - AccountDetails.Transfer.Action.CoordinatingAction
public extension AccountDetails.Transfer.Action {
	enum CoordinatingAction: Equatable {
		case dismissTransfer
	}
}
