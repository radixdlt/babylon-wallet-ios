import Foundation
import Models
import Peer
import Profile

public extension P2P {
	// MARK: - ConnectionForClient
	struct ConnectionForClient: Equatable, Sendable {
		public let client: P2PClient
		public private(set) var peer: Peer

		public init(
			client: P2PClient,
			peer: Peer
		) {
			self.client = client
			self.peer = peer
		}
	}
}
