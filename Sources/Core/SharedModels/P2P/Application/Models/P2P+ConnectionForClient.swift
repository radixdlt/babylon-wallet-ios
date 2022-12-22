import Foundation
import P2PConnection
import P2PModels
import Profile

public extension P2P {
	// MARK: - ConnectionForClient
	struct ConnectionForClient: Equatable, Sendable {
		public let client: P2PClient
		public private(set) var p2pConnection: P2PConnection

		public init(
			client: P2PClient,
			p2pConnection: P2PConnection
		) {
			self.client = client
			self.p2pConnection = p2pConnection
		}
	}
}
