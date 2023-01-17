import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import ProfileClient

// MARK: AppSettings.State
public extension AppSettings {
	// MARK: State
	struct State: Equatable {
		public var manageP2PClients: ManageP2PClients.State?
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		public var canAddP2PClient: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init(
			manageP2PClients: ManageP2PClients.State? = nil,
			manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State? = nil,
			canAddP2PClient: Bool = false
		) {
			self.manageP2PClients = manageP2PClients
			self.manageGatewayAPIEndpoints = manageGatewayAPIEndpoints
			self.canAddP2PClient = canAddP2PClient
		}
	}
}
