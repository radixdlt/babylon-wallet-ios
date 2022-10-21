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
		isValid: false,
		accounts: .init(
			uniqueElements: [
				.placeholder,
			]
		),
		accountLimit: 1
	)
}
#endif
