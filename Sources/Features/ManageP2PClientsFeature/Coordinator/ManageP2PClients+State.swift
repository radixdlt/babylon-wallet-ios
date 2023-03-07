import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PClients.State
extension ManageP2PClients {
	public struct State: Sendable, Hashable {
		public var clients: IdentifiedArrayOf<ManageP2PClient.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(
			clients: IdentifiedArrayOf<ManageP2PClient.State> = .init(),
			destination: Destinations.State? = nil
		) {
			self.clients = clients
			self.destination = destination
		}
	}
}

#if DEBUG
extension ManageP2PClients.State {
	public static let previewValue: Self = .init()
}
#endif
