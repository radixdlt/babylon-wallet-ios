import BrowserExtensionsConnectivityClient
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import IdentifiedCollections
import InputPasswordFeature
import Profile

// MARK: - ManageBrowserExtensionConnections.State
public extension ManageBrowserExtensionConnections {
	struct State: Equatable {
		public var connections: IdentifiedArrayOf<BrowserExtensionWithConnectionStatus>

		public var unhandledReceivedMessages: IdentifiedArrayOf<IncomingMessageFromBrowser>
		public var presentedReceivedMessage: IncomingMessageFromBrowser?

		public var inputBrowserExtensionConnectionPassword: InputPassword.State?
		public var connectUsingPassword: ConnectUsingPassword.State?

		public init(
			connections: IdentifiedArrayOf<BrowserExtensionWithConnectionStatus> = .init(),
			unhandledReceivedMessages: IdentifiedArrayOf<IncomingMessageFromBrowser> = .init(),
			presentedReceivedMessage: IncomingMessageFromBrowser? = nil,
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
