import FeaturePrelude

// MARK: - NewConnection.State
extension NewConnection {
	public enum State: Equatable {
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
extension NewConnection.State {
	public static let previewValue: Self = .init()
}
#endif
