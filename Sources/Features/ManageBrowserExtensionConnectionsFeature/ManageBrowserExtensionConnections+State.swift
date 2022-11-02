import BrowserExtensionsConnectivityClient
import ComposableArchitecture
import ConnectUsingPasswordFeature
import Converse
import ConverseCommon
import Foundation
import InputPasswordFeature
import Profile

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
