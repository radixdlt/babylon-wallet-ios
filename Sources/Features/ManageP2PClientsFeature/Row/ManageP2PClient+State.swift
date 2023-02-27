import FeaturePrelude

// MARK: - ManageP2PClient.State
extension ManageP2PClient {
//	typealias State = P2P.ClientWithConnectionStatus
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ConnectionPassword
		public var id: ID { client.connectionPassword }
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

extension ManageP2PClient.State {
	public init(clientWithConnectionStatus: P2P.ClientWithConnectionStatus) {
		self.init(
			client: clientWithConnectionStatus.p2pClient,
			connectionStatus: clientWithConnectionStatus.connectionStatus
		)
	}
}

#if DEBUG
extension ManageP2PClient.State {
	public static let previewValue: Self = .init(clientWithConnectionStatus: .init(p2pClient: .previewValue))
}
#endif
