import ComposableArchitecture
import Foundation
import P2PModels

// MARK: - LocalNetworkPermission.Action
public extension LocalNetworkPermission {
	enum Action: Sendable, Equatable {
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - LocalNetworkPermission.Action.ViewAction
public extension LocalNetworkPermission.Action {
	enum ViewAction: Sendable, Equatable {
		public enum PermissionDeniedAlertAction: Sendable, Equatable {
			case dismissed
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case permissionDeniedAlert(PermissionDeniedAlertAction)
	}
}

// MARK: - LocalNetworkPermission.Action.InternalAction
public extension LocalNetworkPermission.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - LocalNetworkPermission.Action.SystemAction
public extension LocalNetworkPermission.Action {
	enum SystemAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}
}

// MARK: - LocalNetworkPermission.Action.DelegateAction
public extension LocalNetworkPermission.Action {
	enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}
}
