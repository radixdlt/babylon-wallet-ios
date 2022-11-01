import ComposableArchitecture
import Foundation

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var canProceed: Bool
		public var accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>

		public init(
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			canProceed: Bool = false,
			accounts: IdentifiedArrayOf<ChooseAccounts.Row.State>
		) {
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.canProceed = canProceed
			self.accounts = accounts
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
		canProceed: false,
		accounts: .init(
			uniqueElements: [
				.placeholderOne,
			]
		)
	)
}
#endif
