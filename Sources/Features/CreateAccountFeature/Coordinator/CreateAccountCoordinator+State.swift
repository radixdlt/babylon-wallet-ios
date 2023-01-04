import Foundation
import Common

public extension CreateAccountCoordinator {

        struct State: Equatable {
                public let completionDestination: CompletionDestination
                public private(set) var root: Root

                public init(completionDestination: CompletionDestination,
                            root: Root = .init()) {
                        self.completionDestination = completionDestination
                        self.root = root
                }
        }
}

public extension CreateAccountCoordinator.State {
        enum Root: Equatable {
                case createAccount(CreateAccount.State)
                case accountCompletion(AccountCompletion.State)

                public init(state: CreateAccount.State = .init()) {
                        self = .createAccount(state)
                }
        }

        enum CompletionDestination: String, Sendable {
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
}
