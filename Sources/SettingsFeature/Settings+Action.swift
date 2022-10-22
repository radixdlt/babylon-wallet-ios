import ComposableArchitecture
import Foundation
import GatewayAPI
import Profile

// MARK: - Settings.Action
public extension Settings {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

public extension Settings.Action {
	enum CoordinatingAction: Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
	}

	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - Settings.Action.InternalAction.UserAction
public extension Settings.Action.InternalAction {
	enum SystemAction: Equatable {
		#if DEBUG
		case profileToDebugLoaded(Profile)
		#endif // DEBUG
		case viewDidAppear
		case loadRDXLedgerEpoch
		case fetchEpochResult(TaskResult<V0StateEpochResponse>)
	}

	enum UserAction: Equatable {
		case dismissSettings
		case deleteProfileAndFactorSources
		#if DEBUG
		case debugInspectProfile
		case setDebugProfileSheet(isPresented: Bool)
		#endif // DEBUG
	}
}
