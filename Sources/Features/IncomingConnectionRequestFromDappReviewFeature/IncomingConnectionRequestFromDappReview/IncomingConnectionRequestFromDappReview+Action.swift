import Collections
import ComposableArchitecture
import Foundation
import NonEmpty
import Profile

// MARK: - IncomingConnectionRequestFromDappReview.Action
public extension IncomingConnectionRequestFromDappReview {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case chooseAccounts(ChooseAccounts.Action)
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
		case proceedWithConnectionRequest
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction.SystemAction
public extension IncomingConnectionRequestFromDappReview.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadAccountsResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.CoordinatingAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum CoordinatingAction: Equatable {
		case dismissIncomingConnectionRequest
		case proceedWithConnectionRequest
	}
}
