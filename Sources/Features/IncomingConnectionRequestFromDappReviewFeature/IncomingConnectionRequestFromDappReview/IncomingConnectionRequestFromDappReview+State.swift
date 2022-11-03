import Foundation
import Profile

// MARK: - IncomingConnectionRequestFromDappReview.State
public extension IncomingConnectionRequestFromDappReview {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var chooseAccounts: ChooseAccounts.State?

		public init(
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			chooseAccounts: ChooseAccounts.State? = nil
		) {
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.chooseAccounts = chooseAccounts
		}
	}
}

public extension IncomingConnectionRequestFromDappReview.State {
	init(
		incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
		accounts: [OnNetwork.Account]
	) {
		self.init(
			incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
			chooseAccounts: .init(
				incomingConnectionRequestFromDapp: incomingConnectionRequestFromDapp,
				accounts: .init(uniqueElements: accounts.map { .init(account: $0) })
			)
		)
	}
}

#if DEBUG
public extension IncomingConnectionRequestFromDappReview.State {
	static let placeholder: Self = .init(
		incomingConnectionRequestFromDapp: .placeholder
	)
}
#endif
