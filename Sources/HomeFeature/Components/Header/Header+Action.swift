import Foundation

public extension Home.Header {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Header.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.Header.Action.InternalAction {
	enum UserAction: Equatable {
		case settingsButtonTapped
	}
}

public extension Home.Header.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
	}
}
