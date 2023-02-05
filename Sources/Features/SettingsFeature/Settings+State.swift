import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import ConnectedDAppsFeature
import PersonasFeature
import ProfileClient

// MARK: AppSettings.State
public extension AppSettings {
	// MARK: State
	struct State: Equatable {
		public var manageP2PClients: ManageP2PClients.State?
		public var connectedDApps: PresentationState<ConnectedDApps.State>
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		public var personasCoordinator: PersonasCoordinator.State?
		public var canAddP2PClient: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init(
			manageP2PClients: ManageP2PClients.State? = nil,
			connectedDApps: PresentationState<ConnectedDApps.State> = .dismissed,
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
