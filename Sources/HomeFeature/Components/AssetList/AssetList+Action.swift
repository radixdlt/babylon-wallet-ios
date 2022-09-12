import Foundation

public extension Home.AssetList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.AssetList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AssetList.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension Home.AssetList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.AssetList.Action {
	enum CoordinatingAction: Equatable {}
}
