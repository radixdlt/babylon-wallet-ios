import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - NewConnection.State
public extension NewConnection {
	struct State: Equatable {
		enum Route: Equatable {
			case localNetworkAuthorization
			case scanQR(ScanQR.State)
			case connectUsingSecrets(ConnectUsingSecrets.State)
		}

		var route: Route
		var localAuthorizationDeniedAlert: AlertState<Action.ViewAction.LocalAuthorizationDeniedAlertAction>?

		public init() {
			self.route = .localNetworkAuthorization
			self.localAuthorizationDeniedAlert = nil
		}
	}
}

#if DEBUG
public extension NewConnection.State {
	static let previewValue: Self = .init()
}
#endif
