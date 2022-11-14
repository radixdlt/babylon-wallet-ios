import Foundation
import GatewayAPI
import ManageBrowserExtensionConnectionsFeature
import Profile

// MARK: Settings.State
public extension Settings {
	// MARK: State
	struct State: Equatable {
		public var manageBrowserExtensionConnections: ManageBrowserExtensionConnections.State?
		public var canAddBrowserExtensionConnection: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif // DEBUG

		public init(
			manageBrowserExtensionConnections: ManageBrowserExtensionConnections.State? = nil,
			canAddBrowserExtensionConnection: Bool = false
		) {
			self.manageBrowserExtensionConnections = manageBrowserExtensionConnections
			self.canAddBrowserExtensionConnection = canAddBrowserExtensionConnection
		}
	}
}
