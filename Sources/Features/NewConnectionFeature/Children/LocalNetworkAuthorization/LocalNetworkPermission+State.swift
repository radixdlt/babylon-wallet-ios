import FeaturePrelude

// MARK: - LocalNetworkPermission.State
extension LocalNetworkPermission {
	public struct State: Sendable, Equatable {
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>?

		init() {
			self.permissionDeniedAlert = nil
		}
	}
}

#if DEBUG
extension LocalNetworkPermission.State {
	public static let previewValue: Self = .init()
}
#endif
