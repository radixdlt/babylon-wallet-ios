import FeaturePrelude
import P2PModels

// MARK: - CameraPermission.Action
public extension CameraPermission {
	enum Action: Sendable, Equatable {
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CameraPermission.Action.ViewAction
public extension CameraPermission.Action {
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

// MARK: - CameraPermission.Action.InternalAction
public extension CameraPermission.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CameraPermission.Action.SystemAction
public extension CameraPermission.Action {
	enum SystemAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}
}

// MARK: - CameraPermission.Action.DelegateAction
public extension CameraPermission.Action {
	enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}
}
