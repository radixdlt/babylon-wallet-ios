import Foundation

public extension Home.VisitHub {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.VisitHub.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.VisitHub.Action.InternalAction {
	enum UserAction: Equatable {
		case visitHubButtonTapped
	}
}

public extension Home.VisitHub.Action {
	enum CoordinatingAction: Equatable {
		case displayHub
	}
}
