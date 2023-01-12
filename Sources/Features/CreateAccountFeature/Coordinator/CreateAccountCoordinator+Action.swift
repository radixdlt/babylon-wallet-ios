import FeaturePrelude
import Profile

// MARK: - CreateAccountCoordinator.Action
public extension CreateAccountCoordinator {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
	}
}

// MARK: - CreateAccountCoordinator.Action.ChildAction
public extension CreateAccountCoordinator.Action {
	enum ChildAction: Sendable, Equatable {
		case createAccount(CreateAccount.Action)
		case accountCompletion(AccountCompletion.Action)
	}
}

// MARK: - CreateAccountCoordinator.Action.DelegateAction
public extension CreateAccountCoordinator.Action {
	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}
}
