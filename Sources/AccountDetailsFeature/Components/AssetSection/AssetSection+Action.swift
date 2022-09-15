import AccountWorthFetcher
import Foundation

public extension AccountDetails.AssetSection {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: Token.Code, action: AccountDetails.AssetRow.Action)
	}
}

public extension AccountDetails.AssetSection.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AccountDetails.AssetSection.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AccountDetails.AssetSection.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AccountDetails.AssetSection.Action {
	enum CoordinatingAction: Equatable {}
}
