import Foundation
import ComposableArchitecture
import Profile

public extension Home.AccountList {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case account(id: UUID, action: Home.AccountRow.Action)
	}
}

public extension Home.AccountList.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Home.AccountList.Action.InternalAction {
	enum UserAction: Equatable {
        case alertDismissed
    }
}

public extension Home.AccountList.Action.InternalAction {
	enum SystemAction: Equatable {
        case viewDidAppear
        case loadAccountResult(TaskResult<[Profile.Account]>)
    }
}

public extension Home.AccountList.Action {
	enum CoordinatingAction: Equatable {}
}
