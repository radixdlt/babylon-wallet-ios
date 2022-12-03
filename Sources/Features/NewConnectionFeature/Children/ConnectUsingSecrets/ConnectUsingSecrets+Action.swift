import ChunkingTransport
import ComposableArchitecture
import Converse
import Foundation

// MARK: - ConnectUsingSecrets.Action
public extension ConnectUsingSecrets {
	enum Action: Sendable, Equatable {
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

public extension ConnectUsingSecrets.Action {
	static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
}

// MARK: - ConnectUsingSecrets.Action.ViewAction
public extension ConnectUsingSecrets.Action {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - ConnectUsingSecrets.Action.InternalAction
public extension ConnectUsingSecrets.Action {
	enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - ConnectUsingSecrets.Action.SystemAction
public extension ConnectUsingSecrets.Action {
	enum SystemAction: Sendable, Equatable {
		case establishConnectionResult(TaskResult<Connection>)
	}
}

// MARK: - ConnectUsingSecrets.Action.DelegateAction
public extension ConnectUsingSecrets.Action {
	enum DelegateAction: Sendable, Equatable {
		case connected(Connection)
	}
}
