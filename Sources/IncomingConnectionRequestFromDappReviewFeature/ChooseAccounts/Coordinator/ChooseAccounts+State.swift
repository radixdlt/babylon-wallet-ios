import Foundation
import ComposableArchitecture

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var isValid: Bool
        public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
        public let accountLimit: Int
        
        public init(
            incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
            isValid: Bool = false,
            accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>,
            accountLimit: Int
        ) {
            self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
            self.isValid = isValid
            self.accounts = accounts
            self.accountLimit = accountLimit
        }
	}
}

#if DEBUG
public extension ChooseAccounts.State {
	static let placeholder: Self = .init(
		incomingConnectionRequestFromDapp: .placeholder,
        isValid: true,
        accounts: .init(
            uniqueElements: [
                .init(account: .init(address: "some address 1", name: "Some Name 1")),
                .init(account: .init(address: "some address 2", name: "Some Name 2")),
                .init(account: .init(address: "some address 3", name: "Some Name 3"))
            ]
        ),
        accountLimit: 2
    )
}
#endif
