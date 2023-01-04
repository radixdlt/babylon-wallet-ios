import Foundation

public extension CreateAccountCoordinator {
	enum State: Equatable {
		case createAccount(CreateAccount.State)
		case accountCompletion(AccountCompletion.State)
	}
}
