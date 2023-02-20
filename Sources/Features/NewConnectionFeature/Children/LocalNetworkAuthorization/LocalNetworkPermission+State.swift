import FeaturePrelude

// MARK: - LocalNetworkPermission.State
extension LocalNetworkPermission {
	public struct State: Sendable, Equatable {
		@PresentationState
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>? = nil

		init() {}
	}
}

#if DEBUG
extension LocalNetworkPermission.State {
	public static let previewValue: Self = .init()
}
#endif
