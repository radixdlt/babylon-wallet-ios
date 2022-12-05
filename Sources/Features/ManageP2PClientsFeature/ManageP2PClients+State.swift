import Converse
import ConverseCommon
import Foundation
import IdentifiedCollections
import NewConnectionFeature
import P2PConnectivityClient
import Profile
import SharedModels

// MARK: - ManageP2PClients.State
public extension ManageP2PClients {
	struct State: Equatable {
		public var connections: IdentifiedArrayOf<P2P.ClientWithConnectionStatus>

		public var newConnection: NewConnection.State?

		public init(
			connections: IdentifiedArrayOf<P2P.ClientWithConnectionStatus> = .init(),
			newConnection: NewConnection.State? = nil
		) {
			self.connections = connections

			self.newConnection = newConnection
		}
	}
}
