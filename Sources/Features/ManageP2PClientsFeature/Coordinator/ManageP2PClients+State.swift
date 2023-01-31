import FeaturePrelude
import NewConnectionFeature
import P2PConnectivityClient

// MARK: - ManageP2PClients.State
public extension ManageP2PClients {
	struct State: Equatable {
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
public extension ManageP2PClients.State {
	static let previewValue: Self = .init()
}
#endif
