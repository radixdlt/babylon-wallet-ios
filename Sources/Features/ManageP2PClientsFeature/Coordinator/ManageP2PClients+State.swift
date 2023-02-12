import FeaturePrelude
import NewConnectionFeature
import P2PConnectivityClient

// MARK: - ManageP2PClients.State
extension ManageP2PClients {
	public struct State: Equatable {
		public var clients: IdentifiedArrayOf<ManageP2PClient.State>

		public var newConnection: NewConnection.State?

		public init(
			clients: IdentifiedArrayOf<ManageP2PClient.State> = .init(),
			newConnection: NewConnection.State? = nil
		) {
			self.clients = clients
			self.newConnection = newConnection
		}
	}
}

#if DEBUG
extension ManageP2PClients.State {
	public static let previewValue: Self = .init()
}
#endif
