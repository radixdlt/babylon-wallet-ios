import Foundation

public extension Home.AssetSection {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case asset(id: UUID, action: Home.AssetRow.Action)
	}
}

public extension Home.AssetSection.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AssetSection.Action.InternalAction {
	enum UserAction: Equatable {}
}

public extension Home.AssetSection.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.AssetSection.Action {
	enum CoordinatingAction: Equatable {}
}
