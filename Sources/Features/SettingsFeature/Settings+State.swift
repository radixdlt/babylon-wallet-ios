import ConnectedDAppsFeature
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import PersonasFeature
import ProfileClient

// MARK: AppSettings.State
extension AppSettings {
	// MARK: State
	public struct State: Equatable {
		public var manageP2PClients: ManageP2PClients.State?
		@PresentationState public var connectedDapps: ConnectedDapps.State?
		public var manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State?
		public var personasCoordinator: PersonasCoordinator.State?
		public var canAddP2PClient: Bool
		#if DEBUG
		public var profileToInspect: Profile?
		#endif

		public init(
			manageP2PClients: ManageP2PClients.State? = nil,
			connectedDapps: ConnectedDapps.State? = nil,
			manageGatewayAPIEndpoints: ManageGatewayAPIEndpoints.State? = nil,
			personasCoordinator: PersonasCoordinator.State? = nil,
			canAddP2PClient: Bool = false
		) {
			self.manageP2PClients = manageP2PClients
			self.connectedDapps = connectedDapps
			self.manageGatewayAPIEndpoints = manageGatewayAPIEndpoints
			self.personasCoordinator = personasCoordinator
			self.canAddP2PClient = canAddP2PClient
		}
	}
}
