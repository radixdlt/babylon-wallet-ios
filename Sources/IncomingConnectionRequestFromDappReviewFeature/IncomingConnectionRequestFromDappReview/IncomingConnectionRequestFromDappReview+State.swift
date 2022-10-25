import Foundation

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

#if DEBUG
public extension IncomingConnectionRequestFromDappReview.State {
	static let placeholder: Self = .init(
		incomingConnectionRequestFromDapp: .placeholder
	)
}
#endif
