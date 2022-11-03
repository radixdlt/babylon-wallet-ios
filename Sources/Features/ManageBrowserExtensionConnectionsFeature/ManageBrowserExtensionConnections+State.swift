import BrowserExtensionsConnectivityClient
import ChunkingTransport
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import IdentifiedCollections
import InputPasswordFeature
import Profile

// MARK: - ChunkingTransport.IncomingMessage + Identifiable
extension ChunkingTransport.IncomingMessage: Identifiable {
	public typealias ID = ChunkedMessagePackage.MessageID
	public var id: ID { messageID }
}

// MARK: - ManageBrowserExtensionConnections.State
public extension ManageBrowserExtensionConnections {
	struct State: Equatable {
		public var connections: IdentifiedArrayOf<BrowserExtensionWithConnectionStatus>

		public var unhandledReceivedMessages: IdentifiedArrayOf<ChunkingTransport.IncomingMessage>
		public var presentedReceivedMessage: ChunkingTransport.IncomingMessage?

		public var inputBrowserExtensionConnectionPassword: InputPassword.State?
		public var connectUsingPassword: ConnectUsingPassword.State?

		public init(
			connections: IdentifiedArrayOf<BrowserExtensionWithConnectionStatus> = .init(),
			unhandledReceivedMessages: IdentifiedArrayOf<ChunkingTransport.IncomingMessage> = .init(),
			presentedReceivedMessage: ChunkingTransport.IncomingMessage? = nil,
			inputBrowserExtensionConnectionPassword: InputPassword.State? = nil,
			connectUsingPassword: ConnectUsingPassword.State? = nil
		) {
			self.connections = connections

			self.unhandledReceivedMessages = unhandledReceivedMessages
			self.presentedReceivedMessage = presentedReceivedMessage

			self.inputBrowserExtensionConnectionPassword = inputBrowserExtensionConnectionPassword
			self.connectUsingPassword = connectUsingPassword
		}
	}
}
