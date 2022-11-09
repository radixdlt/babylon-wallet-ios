import ComposableArchitecture
import Foundation
import GatewayAPI
import ManageBrowserExtensionConnectionsFeature
import Profile

// MARK: - Settings.Action
public extension Settings {
	// MARK: Action
	enum Action: Equatable {
		case child(ChildAction)
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension Settings.Action {
	enum ChildAction: Equatable {
		case manageBrowserExtensionConnections(ManageBrowserExtensionConnections.Action)
	}
}

public extension Settings.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Settings.Action {
	enum DelegateAction: Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
	}
}

// MARK: - Settings.Action.InternalAction.UserAction
public extension Settings.Action.InternalAction {
	enum SystemAction: Equatable {
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif // DEBUG
		case viewDidAppear
	}

	enum UserAction: Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		case goToBrowserExtensionConnections
		#if DEBUG
		case debugInspectProfile
		case setDebugProfileSheet(isPresented: Bool)
		#endif // DEBUG
	}
}
