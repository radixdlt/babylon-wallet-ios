import AccountWorthFetcher
import Foundation

public extension AssetList.Section {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: Token.Code, action: AssetList.Row.Action)
	}
}

public extension AssetList.Section.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AssetList.Section.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AssetList.Section.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AssetList.Section.Action {
	enum CoordinatingAction: Equatable {}
}
