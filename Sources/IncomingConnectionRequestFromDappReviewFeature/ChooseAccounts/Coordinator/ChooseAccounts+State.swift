import ComposableArchitecture
import Foundation

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var isValid: Bool
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		public let accountLimit: Int
		public var selectedAccounts: [ChooseAccounts.Row.State]

		public init(
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			isValid: Bool = false,
			accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>,
			accountLimit: Int,
			selectedAccounts: [ChooseAccounts.Row.State] = []
		) {
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.isValid = isValid
			self.accounts = accounts
			self.accountLimit = accountLimit
			self.selectedAccounts = selectedAccounts
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
				.init(account: .init(address: "account1address-deadbeef", name: "My account 1")),
				.init(account: .init(address: "account2address-deadbeef", name: "My account 2")),
//				.init(account: .init(address: "account3address-deadbeef", name: "My account 3")),
//				.init(account: .init(address: "account4address-deadbeef", name: "My account 4")),
//				.init(account: .init(address: "account5address-deadbeef", name: "My account 5")),
			]
		),
		accountLimit: 2
	)
}
#endif
