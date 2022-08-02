import Foundation

public extension Home {
	// MARK: Action
	enum Action: Equatable {
		case header(Home.Header.Action)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Action {
	enum CoordinatingAction: Equatable {
		case displaySettings
	}
}
