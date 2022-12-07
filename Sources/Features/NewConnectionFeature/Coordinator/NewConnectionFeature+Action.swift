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
		case appeared
		case dismissButtonTapped
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
	enum SystemAction: Sendable, Equatable {}
}

// MARK: - NewConnection.Action.DelegateAction
public extension NewConnection.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismiss
		case newConnection(P2P.ConnectionForClient)
	}
}
