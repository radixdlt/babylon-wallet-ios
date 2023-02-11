import FeaturePrelude

// MARK: - CameraPermission.State
extension CameraPermission {
	public struct State: Sendable, Equatable {
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>?

		init() {
			self.permissionDeniedAlert = nil
		}
	}
}

#if DEBUG
extension CameraPermission.State {
	public static let previewValue: Self = .init()
}
#endif
