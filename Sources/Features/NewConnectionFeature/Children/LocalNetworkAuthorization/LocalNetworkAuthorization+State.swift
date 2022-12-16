import ComposableArchitecture
import Foundation

// MARK: - LocalNetworkAuthorization.State
public extension LocalNetworkAuthorization {
	struct State: Sendable, Equatable {
		var authorizationDeniedAlert: AlertState<Action.ViewAction.AuthorizationDeniedAlertAction>?

		init() {
			self.authorizationDeniedAlert = nil
		}
	}
}

#if DEBUG
public extension LocalNetworkAuthorization.State {
	static let previewValue: Self = .init()
}
#endif
