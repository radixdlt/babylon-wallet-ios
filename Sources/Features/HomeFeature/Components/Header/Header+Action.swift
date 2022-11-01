import Foundation

// MARK: - Home.Header.Action
public extension Home.Header {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - Home.Header.Action.InternalAction
public extension Home.Header.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - Home.Header.Action.InternalAction.UserAction
public extension Home.Header.Action.InternalAction {
	enum UserAction: Equatable {
		case settingsButtonTapped
	}
}

// MARK: - Home.Header.Action.CoordinatingAction
public extension Home.Header.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
	}
}
