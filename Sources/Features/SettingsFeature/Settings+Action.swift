import FeaturePrelude
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import P2PModels
import Profile

// MARK: - AppSettings.Action
public extension AppSettings {
	// MARK: Action
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AppSettings.Action.ChildAction
public extension AppSettings.Action {
	enum ChildAction: Sendable, Equatable {
		case manageP2PClients(ManageP2PClients.Action)
		case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.Action)
	}
}

// MARK: - AppSettings.Action.ViewAction
public extension AppSettings.Action {
	enum ViewAction: Sendable, Equatable {
		case didAppear
		case dismissSettingsButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped

		case manageP2PClientsButtonTapped
		case addP2PClientButtonTapped

		case editGatewayAPIEndpointButtonTapped

		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif
	}
}

// MARK: - AppSettings.Action.InternalAction
public extension AppSettings.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AppSettings.Action.InternalAction.SystemAction
public extension AppSettings.Action.InternalAction {
	enum SystemAction: Sendable, Equatable {
		case loadP2PClientsResult(TaskResult<P2PClients>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif
	}
}

// MARK: - AppSettings.Action.DelegateAction
public extension AppSettings.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		case networkChanged
	}
}
