import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.Action.InternalActions {
	enum UserAction: Equatable {
		case toggleBalanceVisibilityButtonTapped
		case settingsButtonTapped
		case createNewAccountButtonTapped
		case visitTheRadixHubButtonTapped
	}
}

public extension Home.Action.InternalActions {
	enum SystemAction: Equatable {}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {}
}
