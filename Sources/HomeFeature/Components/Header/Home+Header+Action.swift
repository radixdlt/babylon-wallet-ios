import Foundation

public extension Home.Header {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Header.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.Header.Action.InternalActions {
	enum UserAction: Equatable {
		case settingsButtonTapped
	}
}

public extension Home.Header.Action.InternalActions {
	enum SystemAction: Equatable {}
}

public extension Home.Header.Action {
	enum CoordinatingAction: Equatable {
        case displaySettings
    }
}
