import ComposableArchitecture
import Foundation

// MARK: - LocalNetworkPermission.State
public extension LocalNetworkPermission {
	struct State: Sendable, Equatable {
		var permissionDeniedAlert: AlertState<Action.ViewAction.PermissionDeniedAlertAction>?

		init() {
			self.permissionDeniedAlert = nil
		}
	}
}

#if DEBUG
public extension LocalNetworkPermission.State {
	static let previewValue: Self = .init()
}
#endif
