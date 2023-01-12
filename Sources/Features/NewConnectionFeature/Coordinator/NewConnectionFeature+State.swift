import FeaturePrelude
import Foundation
import SwiftUI

// MARK: - NewConnection.State
public extension NewConnection {
	enum State: Equatable {
		case localNetworkPermission(LocalNetworkPermission.State)
		case cameraPermission(CameraPermission.State)
		case scanQR(ScanQR.State)
		case connectUsingSecrets(ConnectUsingSecrets.State)

		public init() {
			self = .localNetworkPermission(.init())
		}
	}
}

#if DEBUG
public extension NewConnection.State {
	static let previewValue: Self = .init()
}
#endif
