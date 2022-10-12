import Foundation

// MARK: - IncomingConnectionRequestFromDappReview.State
public extension IncomingConnectionRequestFromDappReview {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp

		public init(
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		) {
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
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
