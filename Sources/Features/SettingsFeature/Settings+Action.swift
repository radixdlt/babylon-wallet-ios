import ComposableArchitecture
import Foundation
import GatewayAPI
import ManageGatewayAPIEndpointsFeature
import ManageP2PClientsFeature
import Profile

// MARK: - Settings.Action
public extension Settings {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - Settings.Action.ChildAction
public extension Settings.Action {
	enum ChildAction: Equatable {
		case manageP2PClients(ManageP2PClients.Action)
		case manageGatewayAPIEndpoints(ManageGatewayAPIEndpoints.Action)
	}
}

// MARK: - Settings.Action.ViewAction
public extension Settings.Action {
	enum ViewAction: Equatable {
		case didAppear
		case dismissSettingsButtonTapped
		case deleteProfileAndFactorSourcesButtonTapped

		case manageP2PClientsButtonTapped
		case addP2PClientButtonTapped

		case editGatewayAPIEndpointButtonTapped

		#if DEBUG
		case debugInspectProfileButtonTapped
		case setDebugProfileSheet(isPresented: Bool)
		#endif // DEBUG
	}
}

// MARK: - Settings.Action.InternalAction
public extension Settings.Action {
	enum InternalAction: Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - Settings.Action.InternalAction.SystemAction
public extension Settings.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadP2PClientsResult(TaskResult<P2PClients>)
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif // DEBUG
	}
}

// MARK: - Settings.Action.DelegateAction
public extension Settings.Action {
	enum DelegateAction: Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
	}
}
