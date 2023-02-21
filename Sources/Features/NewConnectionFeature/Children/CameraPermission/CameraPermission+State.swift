import FeaturePrelude

// MARK: - CameraPermission.State
extension CameraPermission {
	public struct State: Sendable, Hashable {
		@PresentationState
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>? = nil

		init() {}
	}
}

#if DEBUG
extension CameraPermission.State {
	public static let previewValue: Self = .init()
}
#endif
