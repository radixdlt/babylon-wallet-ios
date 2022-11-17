import Collections
import ComposableArchitecture
import Foundation
import NonEmpty
import Profile
import SharedModels

// MARK: - IncomingConnectionRequestFromDappReview.Action
public extension IncomingConnectionRequestFromDappReview {
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.ChildAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum ChildAction: Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.ViewAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum ViewAction: Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.DelegateAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum DelegateAction: Equatable {
		case finishedChoosingAccounts(
			NonEmpty<OrderedSet<OnNetwork.Account>>,
			request: P2P.OneTimeAccountAddressesRequestToHandle
		)

		case dismiss
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction
public extension IncomingConnectionRequestFromDappReview.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - IncomingConnectionRequestFromDappReview.Action.InternalAction.SystemAction
public extension IncomingConnectionRequestFromDappReview.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadAccountsResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
	}
}
