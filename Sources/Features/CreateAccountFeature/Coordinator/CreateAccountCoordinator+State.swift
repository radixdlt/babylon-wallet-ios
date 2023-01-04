import Common
import Foundation

// MARK: - CreateAccountCoordinator.State
public extension CreateAccountCoordinator {
	struct State: Equatable {
		public let completionDestination: CrateAccountCompletionDestination
		public var root: Root

		public init(completionDestination: CrateAccountCompletionDestination,
		            rootState: Root.InitialState = .init())
		{
			self.completionDestination = completionDestination
			self.root = .init(state: rootState)
		}
	}
}

// MARK: - CreateAccountCoordinator.State.Root
public extension CreateAccountCoordinator.State {
	enum Root: Equatable {
		public typealias InitialState = CreateAccount.State
		case createAccount(CreateAccount.State)
		case accountCompletion(AccountCompletion.State)

		public init(state: InitialState = .init()) {
			self = .createAccount(state)
		}
	}
}

// MARK: - CrateAccountCompletionDestination
public enum CrateAccountCompletionDestination: String, Sendable {
	case home
	case chooseAccounts

	var displayText: String {
		switch self {
		case .home:
			return L10n.CreateAccount.Completion.Destination.home
		case .chooseAccounts:
			return L10n.CreateAccount.Completion.Destination.chooseAccounts
		}
	}
}
