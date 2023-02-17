import FeaturePrelude
import P2PModels

// MARK: - LocalNetworkPermission.Action
extension LocalNetworkPermission {
	public enum Action: Sendable, Equatable {
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - LocalNetworkPermission.Action.ViewAction
extension LocalNetworkPermission.Action {
	public enum ViewAction: Sendable, Equatable {
		public enum PermissionDeniedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case permissionDeniedAlert(PresentationAction<AlertState<PermissionDeniedAlertAction>, PermissionDeniedAlertAction>)
	}
}

// MARK: - LocalNetworkPermission.Action.InternalAction
extension LocalNetworkPermission.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - LocalNetworkPermission.Action.SystemAction
extension LocalNetworkPermission.Action {
	public enum SystemAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}
}

// MARK: - LocalNetworkPermission.Action.DelegateAction
extension LocalNetworkPermission.Action {
	public enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}
}
