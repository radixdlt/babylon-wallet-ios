import Foundation

// MARK: - PersonaConnectionRequest.Action
public extension PersonaConnectionRequest {
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - PersonaConnectionRequest.Action.InternalAction
public extension PersonaConnectionRequest.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - PersonaConnectionRequest.Action.InternalAction.UserAction
public extension PersonaConnectionRequest.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - PersonaConnectionRequest.Action.InternalAction.SystemAction
public extension PersonaConnectionRequest.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - PersonaConnectionRequest.Action.CoordinatingAction
public extension PersonaConnectionRequest.Action {
	enum CoordinatingAction: Equatable {}
}
