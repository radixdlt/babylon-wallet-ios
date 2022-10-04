import AccountWorthFetcher
import Foundation

// MARK: - AssetList.Section.Action
public extension AssetList.Section {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: Token.Code, action: AssetList.Row.Action)
	}
}

// MARK: - AssetList.Section.Action.InternalAction
public extension AssetList.Section.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

// MARK: - AssetList.Section.Action.InternalAction.UserAction
public extension AssetList.Section.Action.InternalAction {
	enum UserAction: Equatable {}
}

// MARK: - AssetList.Section.Action.InternalAction.SystemAction
public extension AssetList.Section.Action.InternalAction {
	enum SystemAction: Equatable {}
}

// MARK: - AssetList.Section.Action.CoordinatingAction
public extension AssetList.Section.Action {
	enum CoordinatingAction: Equatable {}
}
