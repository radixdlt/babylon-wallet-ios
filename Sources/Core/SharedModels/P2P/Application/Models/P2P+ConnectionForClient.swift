import Foundation
import P2PConnection
import P2PModels
import Profile

public extension P2P {
	// MARK: - ConnectionForClient
	struct ConnectionForClient: Equatable, Sendable {
		public let client: P2PClient
		public private(set) var peer: P2PConnection

		public init(
			client: P2PClient,
			peer: P2PConnection
		) {
			self.client = client
			self.peer = peer
		}
	}
}
