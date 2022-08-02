import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case component(ComponentAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Action {
	enum ComponentAction: Equatable {
        case header(Home.Header.Action)
	}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {
        case displaySettings
    }
}
