import Foundation
import GatewayAPI
import ManageBrowserExtensionConnectionsFeature
import Profile

// MARK: Settings.State
public extension Settings {
	// MARK: State
	struct State: Equatable {
		public var manageBrowserExtensionConnections: ManageBrowserExtensionConnections.State?
		#if DEBUG
		public var profileToInspect: Profile?
		#endif // DEBUG

		public init(
			manageBrowserExtensionConnections: ManageBrowserExtensionConnections.State? = nil
		) {
			self.manageBrowserExtensionConnections = manageBrowserExtensionConnections
		}
	}
}
