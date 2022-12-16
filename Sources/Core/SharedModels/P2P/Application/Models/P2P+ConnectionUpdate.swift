import Foundation
import Models
import Profile

// MARK: - P2P.ConnectionUpdate
public extension P2P {
	// MARK: - ConnectionUpdate
	struct ConnectionUpdate: Sendable, Equatable, Identifiable {
		public let connectionStatus: ConnectionStatus
		public let p2pClient: P2PClient

		public init(connectionStatus: ConnectionStatus, p2pClient: P2PClient) {
			self.connectionStatus = connectionStatus
			self.p2pClient = p2pClient
		}
	}
}

public extension P2P.ConnectionUpdate {
	typealias ID = P2PClient.ID
	var id: ID {
		p2pClient.id
	}
}
