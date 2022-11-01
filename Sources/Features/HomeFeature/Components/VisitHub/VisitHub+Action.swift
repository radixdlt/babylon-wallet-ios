import Foundation

// MARK: - Home.VisitHub.Action
public extension Home.VisitHub {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - Home.VisitHub.Action.InternalAction
public extension Home.VisitHub.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - Home.VisitHub.Action.InternalAction.UserAction
public extension Home.VisitHub.Action.InternalAction {
	enum UserAction: Equatable {
		case visitHubButtonTapped
	}
}

// MARK: - Home.VisitHub.Action.CoordinatingAction
public extension Home.VisitHub.Action {
	enum CoordinatingAction: Equatable {
		case displayHub
	}
}
