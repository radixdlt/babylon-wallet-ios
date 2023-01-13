import P2PModels
import Prelude
import ProfileModels

// MARK: - P2P.ClientWithConnectionStatus
public extension P2P {
	// MARK: - ClientWithConnectionStatus
	struct ClientWithConnectionStatus: Sendable, Identifiable, Hashable {
		public let p2pClient: P2PClient
		public var connectionStatus: ConnectionStatus

		public init(
			p2pClient: P2PClient,
			connectionStatus: ConnectionStatus = .disconnected
		) {
			self.p2pClient = p2pClient
			self.connectionStatus = connectionStatus
		}
	}
}

public extension P2P.ClientWithConnectionStatus {
	typealias ID = P2PClient.ID
	var id: ID { p2pClient.id }
}
