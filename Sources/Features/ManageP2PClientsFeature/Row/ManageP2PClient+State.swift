import FeaturePrelude

// MARK: - ManageP2PClient.State
public extension ManageP2PClient {
//	typealias State = P2P.ClientWithConnectionStatus
	struct State: Sendable, Hashable, Identifiable {
		public typealias ID = P2PClient.ID
		public var id: ID { client.id }
		public let client: P2PClient

		public var connectionStatus: ConnectionStatus

		#if DEBUG
		public var webSocketState: WebSocketState
		public var dataChannelStatus: DataChannelState
		public init(
			client: P2PClient,
			connectionStatus: ConnectionStatus = .new,
			webSocketState: WebSocketState = .new,
			dataChannelStatus: DataChannelState = .closed
		) {
			self.client = client
			self.connectionStatus = connectionStatus
			self.webSocketState = webSocketState
			self.dataChannelStatus = dataChannelStatus
		}
		#else
		public init(
			client: P2PClient,
			connectionStatus: ConnectionStatus = .new
		) {
			self.client = client
			self.connectionStatus = connectionStatus
		}
		#endif
	}
}

public extension ManageP2PClient.State {
	init(clientWithConnectionStatus: P2P.ClientWithConnectionStatus) {
		self.init(
			client: clientWithConnectionStatus.p2pClient,
			connectionStatus: clientWithConnectionStatus.connectionStatus
		)
	}
}

#if DEBUG
public extension ManageP2PClient.State {
	static let previewValue: Self = .init(clientWithConnectionStatus: .init(p2pClient: .previewValue))
}
#endif
