import Converse
import ConverseCommon
import Foundation
import Profile

public extension P2P {
	// MARK: - ConnectionForClient
	struct ConnectionForClient: Equatable, Sendable {
		public let client: P2PClient
		public private(set) var connection: Connection

		public init(
			client: P2PClient,
			connection: Connection
		) {
			self.client = client
			self.connection = connection
		}
	}
}
