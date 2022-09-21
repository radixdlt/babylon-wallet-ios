import Foundation

public extension AssetList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case section(id: AssetCategory.CategoryType, action: AssetList.Section.Action)
	}
}

public extension AssetList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AssetList.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AssetList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AssetList.Action {
	enum CoordinatingAction: Equatable {}
}
