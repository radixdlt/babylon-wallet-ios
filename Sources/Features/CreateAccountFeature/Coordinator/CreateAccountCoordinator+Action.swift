import ComposableArchitecture
import Foundation
import Profile

public extension CreateAccountCoordinator {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
		case `internal`(InternalAction)
	}

	enum ChildAction: Sendable, Equatable {
		case createAccount(CreateAccount.Action)
		case accountCompletion(AccountCompletion.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}

// MARK: - CreateAccountCoordinator.Action.InternalAction
public extension CreateAccountCoordinator.Action {
	enum InternalAction: Sendable, Equatable {
		case system(SystemAction)
	}
}

// MARK: - CreateAccountCoordinator.Action.SystemAction
public extension CreateAccountCoordinator.Action {
	enum SystemAction: Sendable, Equatable {
		case injectProfileIntoProfileClientResult(TaskResult<Profile>)
		case loadAccountResult(TaskResult<OnNetwork.Account>)
	}
}
