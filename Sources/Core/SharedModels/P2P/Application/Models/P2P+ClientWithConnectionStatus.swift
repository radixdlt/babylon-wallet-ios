import P2PModels
import Prelude
import ProfileModels

// MARK: - P2P.ClientWithConnectionStatus
extension P2P {
	// MARK: - ClientWithConnectionStatus
	public struct ClientWithConnectionStatus: Sendable, Identifiable, Hashable {
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

extension P2P.ClientWithConnectionStatus {
	public typealias ID = P2PClient.ID
	public var id: ID { p2pClient.id }
}
