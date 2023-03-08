import FeaturePrelude

// MARK: - ManageP2PClient.State
extension ManageP2PClient {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ConnectionPassword
		public var id: ID { client.connectionPassword }
		public let client: P2PClient

		public init(
			client: P2PClient
		) {
			self.client = client
		}
	}
}
