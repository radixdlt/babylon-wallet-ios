import ConnectedDAppsFeature
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient

// MARK: AppSettings.State
public extension AppSettings {
	// MARK: State
	struct State: Equatable {
		public var manageP2PClients: ManageP2PClients.State?
		@PresentationState public var connectedDApps: ConnectedDApps.State?
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		public var personasCoordinator: PersonasCoordinator.State?
		public var canAddP2PClient: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init(
			manageP2PClients: ManageP2PClients.State? = nil,
			connectedDApps: ConnectedDApps.State? = nil,
			manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State? = nil,
			personasCoordinator: PersonasCoordinator.State? = nil,
			canAddP2PClient: Bool = false
		) {
			self.manageP2PClients = manageP2PClients
			self.connectedDApps = connectedDApps
			self.manageGatewayAPIEndpoints = manageGatewayAPIEndpoints
			self.personasCoordinator = personasCoordinator
			self.canAddP2PClient = canAddP2PClient
		}
	}
}
