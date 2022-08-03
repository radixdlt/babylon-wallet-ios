import Foundation

public extension Settings {
	// MARK: Action
	enum Action: Equatable {
		case coordinate(CoordinatingAction)
	}
}

public extension Settings.Action {
	enum CoordinatingAction: Equatable {}
}
