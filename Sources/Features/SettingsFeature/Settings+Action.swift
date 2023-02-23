import ConnectedDAppsFeature
import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import P2PModels
import PersonasFeature
import Profile

// MARK: - AppSettings.Action
extension AppSettings {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AppSettings.Action.ChildAction
extension AppSettings.Action {
	public enum ChildAction: Sendable, Equatable {
		case manageP2PClients(ManageP2PClients.Action)
		case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.Action)
		case connectedDapps(PresentationActionOf<ConnectedDapps>)
		case personasCoordinator(PersonasCoordinator.Action)
	}
}

// MARK: - AppSettings.Action.ViewAction
extension AppSettings.Action {
	public enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissSettingsButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped

		case manageP2PClientsButtonTapped
		case addP2PClientButtonTapped
		case connectedDappsButtonTapped

		case editGatewayAPIEndpointButtonTapped
		case personasButtonTapped

		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif
	}
}

// MARK: - AppSettings.Action.InternalAction
extension AppSettings.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AppSettings.Action.InternalAction.SystemAction
extension AppSettings.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {
		case loadP2PClientsResult(TaskResult<P2PClients>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif
	}
}

// MARK: - AppSettings.Action.DelegateAction
extension AppSettings.Action {
	public enum DelegateAction: Sendable, Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		case networkChanged
	}
}
