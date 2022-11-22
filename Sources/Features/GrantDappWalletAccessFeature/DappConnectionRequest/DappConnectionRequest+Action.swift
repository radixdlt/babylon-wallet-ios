import Collections
import ComposableArchitecture
import Foundation
import NonEmpty
import Profile
import SharedModels

// MARK: - DappConnectionRequest.Action
public extension DappConnectionRequest {
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - DappConnectionRequest.Action.ChildAction
public extension DappConnectionRequest.Action {
	enum ChildAction: Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}
}

// MARK: - DappConnectionRequest.Action.ViewAction
public extension DappConnectionRequest.Action {
	enum ViewAction: Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}
}

// MARK: - DappConnectionRequest.Action.DelegateAction
public extension DappConnectionRequest.Action {
	enum DelegateAction: Equatable {
		case finishedChoosingAccounts(
			NonEmpty<OrderedSet<OnNetwork.Account>>,
			request: P2P.OneTimeAccountAddressesRequestToHandle
		)

		case dismiss(P2P.OneTimeAccountAddressesRequestToHandle)
	}
}

// MARK: - DappConnectionRequest.Action.InternalAction
public extension DappConnectionRequest.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - DappConnectionRequest.Action.InternalAction.SystemAction
public extension DappConnectionRequest.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadAccountsResult(TaskResult<NonEmpty<OrderedSet<OnNetwork.Account>>>)
	}
}
