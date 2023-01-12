import FeaturePrelude
import Foundation

// MARK: - CameraPermission.State
public extension CameraPermission {
	struct State: Sendable, Equatable {
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>?

		init() {
			self.permissionDeniedAlert = nil
		}
	}
}

#if DEBUG
public extension CameraPermission.State {
	static let previewValue: Self = .init()
}
#endif
