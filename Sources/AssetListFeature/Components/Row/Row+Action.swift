import Foundation

public extension AssetList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AssetList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AssetList.Row.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AssetList.Row.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AssetList.Row.Action {
	enum CoordinatingAction: Equatable {}
}
