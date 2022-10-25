import ComposableArchitecture
import Foundation

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

// MARK: - Computed Properties
extension ChooseAccounts.State {
	var selectedAccounts: [ChooseAccounts.Row.State] {
		accounts.filter(\.isSelected)
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
