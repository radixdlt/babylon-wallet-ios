import SharedModels

// MARK: - ManageP2PClient.State
public extension ManageP2PClient {
//	typealias State = P2P.ClientWithConnectionStatus
	struct State: Sendable, Hashable, Identifiable {
		public typealias ID = P2PClient.ID
		public var id: ID { client.id }
		public let client: P2PClient
		public var connectionStatus: ConnectionStatus
		public var webSocketState: WebSocketState
		public init(
			client: P2PClient,
			connectionStatus: ConnectionStatus = .new,
			webSocketState: WebSocketState = .new
		) {
			self.client = client
			self.connectionStatus = connectionStatus
			self.webSocketState = webSocketState
		}
	}
}

public extension ManageP2PClient.State {
	init(clientWithConnectionStatus: P2P.ClientWithConnectionStatus) {
		self.init(client: clientWithConnectionStatus.p2pClient, connectionStatus: clientWithConnectionStatus.connectionStatus)
	}
}
