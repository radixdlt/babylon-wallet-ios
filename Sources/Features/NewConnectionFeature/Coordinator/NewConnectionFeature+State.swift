import Foundation

// MARK: - NewConnection.State
public extension NewConnection {
	enum State: Equatable {
		case scanQR(ScanQR.State)
		case connectUsingSecrets(ConnectUsingSecrets.State)

		public init() {
			self = .scanQR(.init())
		}
	}
}

#if DEBUG
public extension NewConnection.State {
	static let previewValue: Self = .init()
}
#endif
