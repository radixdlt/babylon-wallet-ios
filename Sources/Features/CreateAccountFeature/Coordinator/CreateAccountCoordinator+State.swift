import FeaturePrelude

// MARK: - CreateAccountCoordinator.State
public extension CreateAccountCoordinator {
	struct State: Hashable {
		public let completionDestination: CreateAccountCompletionDestination
		public var root: Root

		public init(
			completionDestination: CreateAccountCompletionDestination,
			rootState: Root.InitialState = .init()
		) {
			self.completionDestination = completionDestination
			self.root = .init(state: rootState)
		}
	}
}

// MARK: - CreateAccountCoordinator.State.Root
public extension CreateAccountCoordinator.State {
	enum Root: Hashable {
		public typealias InitialState = CreateAccount.State
		case createAccount(CreateAccount.State)
		case accountCompletion(AccountCompletion.State)

		public init(state: InitialState = .init()) {
			self = .createAccount(state)
		}
	}
}

// MARK: - CreateAccountCompletionDestination
public enum CreateAccountCompletionDestination: String, Sendable, Hashable {
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
