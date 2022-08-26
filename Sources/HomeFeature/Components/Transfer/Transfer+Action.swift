import Foundation

public extension Home.Transfer {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Home.Transfer.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.Transfer.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissTransfer
	}
}

public extension Home.Transfer.Action.InternalAction {
	enum SystemAction: Equatable {}
}

public extension Home.Transfer.Action {
	enum CoordinatingAction: Equatable {
		case dismissTransfer
	}
}
