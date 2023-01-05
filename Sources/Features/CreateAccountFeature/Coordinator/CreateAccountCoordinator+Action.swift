import ComposableArchitecture
import Foundation
import Profile

public extension CreateAccountCoordinator {
	enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
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
