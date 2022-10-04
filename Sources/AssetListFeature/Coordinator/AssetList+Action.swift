import Foundation

// MARK: - AssetList.Action
public extension AssetList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case section(id: AssetCategory.CategoryType, action: AssetList.Section.Action)
	}
}

// MARK: - AssetList.Action.InternalAction
public extension AssetList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AssetList.Action.InternalAction.UserAction
public extension AssetList.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - AssetList.Action.InternalAction.SystemAction
public extension AssetList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AssetList.Action.CoordinatingAction
public extension AssetList.Action {
	enum CoordinatingAction: Equatable {}
}
