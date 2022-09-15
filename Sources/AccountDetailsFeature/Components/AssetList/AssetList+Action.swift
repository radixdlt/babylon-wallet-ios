import Foundation

public extension AccountDetails.AssetList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case assetSection(id: UUID, action: AccountDetails.AssetSection.Action)
	}
}

public extension AccountDetails.AssetList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension AccountDetails.AssetList.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension AccountDetails.AssetList.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension AccountDetails.AssetList.Action {
	enum CoordinatingAction: Equatable {}
}
