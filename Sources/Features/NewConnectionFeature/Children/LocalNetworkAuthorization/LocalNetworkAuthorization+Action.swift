import ComposableArchitecture
import Foundation
import Models

// MARK: - LocalNetworkAuthorization.Action
public extension LocalNetworkAuthorization {
	enum Action: Sendable, Equatable {
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - LocalNetworkAuthorization.Action.ViewAction
public extension LocalNetworkAuthorization.Action {
	enum ViewAction: Sendable, Equatable {
		public enum AuthorizationDeniedAlertAction: Sendable, Equatable {
			case dismissed
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case authorizationDeniedAlert(AuthorizationDeniedAlertAction)
	}
}

// MARK: - LocalNetworkAuthorization.Action.InternalAction
public extension LocalNetworkAuthorization.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - LocalNetworkAuthorization.Action.SystemAction
public extension LocalNetworkAuthorization.Action {
	enum SystemAction: Sendable, Equatable {
		case displayAuthorizationDeniedAlert
	}
}

// MARK: - LocalNetworkAuthorization.Action.DelegateAction
public extension LocalNetworkAuthorization.Action {
	enum DelegateAction: Sendable, Equatable {
		case localNetworkAuthorizationResponse(Bool)
	}
}
