import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import InputPasswordFeature
import Profile

// MARK: - BrowserExtensionConnectionWithState
public struct BrowserExtensionConnectionWithState: Identifiable, Equatable {
	public typealias ID = BrowserExtensionConnection.ID
	public var id: ID { browserExtensionConnection.id }
	public let browserExtensionConnection: BrowserExtensionConnection
	public let statefulConnection: Connection
	public var connectionStatus: Connection.State
	public init(
		browserExtensionConnection: BrowserExtensionConnection,
		statefulConnection: Connection,
		connectionStatus: Connection.State = .disconnected
	) {
		precondition(browserExtensionConnection.connectionPassword.data.data == statefulConnection.getConnectionPassword().data.data)
		self.browserExtensionConnection = browserExtensionConnection
		self.statefulConnection = statefulConnection
		self.connectionStatus = connectionStatus
	}
}

// MARK: - ManageBrowserExtensionConnections.State
public extension ManageBrowserExtensionConnections {
	struct State: Equatable {
		public var connections: IdentifiedArrayOf<BrowserExtensionConnectionWithState>

		public var inputBrowserExtensionConnectionPassword: InputPassword.State?
		public var connectUsingPassword: ConnectUsingPassword.State?

		public init(
			connections: IdentifiedArrayOf<BrowserExtensionConnectionWithState> = .init(),
			inputBrowserExtensionConnectionPassword: InputPassword.State? = nil,
			connectUsingPassword: ConnectUsingPassword.State? = nil
		) {
			self.connections = connections
			self.inputBrowserExtensionConnectionPassword = inputBrowserExtensionConnectionPassword
			self.connectUsingPassword = connectUsingPassword
		}
	}
}
