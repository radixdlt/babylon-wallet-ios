import Converse
import Foundation
import SharedModels

// MARK: - NewConnection.Action
public extension NewConnection {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)

		case scanQR(ScanQR.Action)
		case connectUsingSecrets(ConnectUsingSecrets.Action)
	}
}

public extension NewConnection.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - NewConnection.Action.ViewAction
public extension NewConnection.Action {
	enum ViewAction: Sendable, Equatable {
		public enum LocalAuthorizationDeniedAlertAction: Sendable, Equatable {
			case dismissed
			case cancelButtonTapped
			case openSettingsButtonTapped
		}

		case appeared
		case dismissButtonTapped
		case localAuthorizationDeniedAlert(LocalAuthorizationDeniedAlertAction)
	}
}

// MARK: - NewConnection.Action.InternalAction
public extension NewConnection.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - NewConnection.Action.SystemAction
public extension NewConnection.Action {
	enum SystemAction: Sendable, Equatable {
		case displayLocalAuthorizationDeniedAlert
	}
}

// MARK: - NewConnection.Action.DelegateAction
public extension NewConnection.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2P.ConnectionForClient)
	}
}
