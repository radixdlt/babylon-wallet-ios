import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - NewConnection.State
public extension NewConnection {
	enum State: Equatable {
		case localNetworkAuthorization(LocalNetworkAuthorization.State)
		case scanQR(ScanQR.State)
		case connectUsingSecrets(ConnectUsingSecrets.State)

		public init() {
			self = .localNetworkAuthorization(.init())
		}
	}
}

#if DEBUG
public extension NewConnection.State {
	static let previewValue: Self = .init()
}
#endif
