import Foundation

// MARK: - IncomingConnectionRequestFromDappReview.Action
public extension IncomingConnectionRequestFromDappReview {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction.UserAction
public extension IncomingConnectionRequestFromDappReview.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissIncomingConnectionRequest
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction.SystemAction
public extension IncomingConnectionRequestFromDappReview.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.CoordinatingAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum CoordinatingAction: Equatable {
		case dismissIncomingConnectionRequest
	}
}
