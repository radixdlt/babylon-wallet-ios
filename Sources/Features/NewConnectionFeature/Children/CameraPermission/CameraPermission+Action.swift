import FeaturePrelude
import P2PModels

// MARK: - CameraPermission.Action
extension CameraPermission {
	public enum Action: Sendable, Equatable {
		static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CameraPermission.Action.ViewAction
extension CameraPermission.Action {
	public enum ViewAction: Sendable, Equatable {
		public enum PermissionDeniedAlertAction: Sendable, Equatable {
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case permissionDeniedAlert(PresentationAction<AlertState<PermissionDeniedAlertAction>, PermissionDeniedAlertAction>)
	}
}

// MARK: - CameraPermission.Action.InternalAction
extension CameraPermission.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - CameraPermission.Action.SystemAction
extension CameraPermission.Action {
	public enum SystemAction: Sendable, Equatable {
		case displayPermissionDeniedAlert
	}
}

// MARK: - CameraPermission.Action.DelegateAction
extension CameraPermission.Action {
	public enum DelegateAction: Sendable, Equatable {
		case permissionResponse(Bool)
	}
}
