import BrowserExtensionsConnectivityClient
import Collections
import ComposableArchitecture
import Foundation
import NonEmpty
import Profile

// MARK: - IncomingConnectionRequestFromDappReview.Action
public extension IncomingConnectionRequestFromDappReview {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case chooseAccounts(ChooseAccounts.Action)

		case delegate(DelegateAction)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.DelegateAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum DelegateAction: Equatable {
		case finishedChoosingAccounts(
			NonEmpty<OrderedSet<OnNetwork.Account>>,
			incomingMessageFromBrowser: IncomingMessageFromBrowser
		)

		case dismiss
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case coordinate(InternalCoordinateAction)
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

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalCoordinateAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum InternalCoordinateAction: Equatable {
		case dismissIncomingConnectionRequest
		case proceedWithConnectionRequest
	}
}
