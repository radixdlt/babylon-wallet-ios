import Foundation

public extension Home.AssetRow {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.AssetRow.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AssetRow.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension Home.AssetRow.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.AssetRow.Action {
	enum CoordinatingAction: Equatable {}
}
