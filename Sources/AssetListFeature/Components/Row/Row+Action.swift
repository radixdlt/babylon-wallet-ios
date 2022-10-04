import Foundation

// MARK: - AssetList.Row.Action
public extension AssetList.Row {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

// MARK: - AssetList.Row.Action.InternalAction
public extension AssetList.Row.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AssetList.Row.Action.InternalAction.UserAction
public extension AssetList.Row.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - AssetList.Row.Action.InternalAction.SystemAction
public extension AssetList.Row.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AssetList.Row.Action.CoordinatingAction
public extension AssetList.Row.Action {
	enum CoordinatingAction: Equatable {}
}
