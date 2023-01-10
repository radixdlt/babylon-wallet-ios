import ComposableArchitecture
import Profile
import RadixFoundation
import SharedModels

// MARK: - DappConnectionRequest.Action
public extension DappConnectionRequest {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - DappConnectionRequest.Action.ChildAction
public extension DappConnectionRequest.Action {
	enum ChildAction: Sendable, Equatable {}
}

// MARK: - DappConnectionRequest.Action.ViewAction
public extension DappConnectionRequest.Action {
	enum ViewAction: Sendable, Equatable {
		case dismissButtonTapped
		case continueButtonTapped
	}
}

// MARK: - DappConnectionRequest.Action.DelegateAction
public extension DappConnectionRequest.Action {
	enum DelegateAction: Sendable, Equatable {
		case allowed(P2P.OneTimeAccountAddressesRequestToHandle)
		case rejected(P2P.OneTimeAccountAddressesRequestToHandle)
	}
}

// MARK: - DappConnectionRequest.Action.InternalAction
public extension DappConnectionRequest.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - DappConnectionRequest.Action.InternalAction.SystemAction
public extension DappConnectionRequest.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {}
}
