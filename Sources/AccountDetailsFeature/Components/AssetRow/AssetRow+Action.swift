import Foundation

public extension AccountDetails.AssetRow {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension AccountDetails.AssetRow.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AccountDetails.AssetRow.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AccountDetails.AssetRow.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AccountDetails.AssetRow.Action {
	enum CoordinatingAction: Equatable {}
}
