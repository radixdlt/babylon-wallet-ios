import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import IdentifiedCollections
import InputPasswordFeature
import P2PConnectivityClient
import Profile
import SharedModels

// MARK: - ManageP2PClients.State
public extension ManageP2PClients {
	struct State: Equatable {
		public var connections: IdentifiedArrayOf<P2P.ClientWithConnectionStatus>

		public var inputP2PConnectionPassword: InputPassword.State?
		public var connectUsingPassword: ConnectUsingPassword.State?

		public init(
			connections: IdentifiedArrayOf<P2P.ClientWithConnectionStatus> = .init(),
			inputP2PConnectionPassword: InputPassword.State? = nil,
			connectUsingPassword: ConnectUsingPassword.State? = nil
		) {
			self.connections = connections

			self.inputP2PConnectionPassword = inputP2PConnectionPassword
			self.connectUsingPassword = connectUsingPassword
		}
	}
}
