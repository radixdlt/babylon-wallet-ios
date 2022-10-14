import Foundation

// MARK: - ChooseAccounts.State
public extension ChooseAccounts {
	struct State: Equatable {
		public let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp
		public var isValid: Bool

		public init(
			incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp,
			isValid: Bool = false
		) {
			self.incomingConnectionRequestFromDapp = incomingConnectionRequestFromDapp
			self.isValid = isValid
		}
	}
}

#if DEBUG
public extension ChooseAccounts.State {
	static let placeholder: Self = .init(
		incomingConnectionRequestFromDapp: .placeholder,
		isValid: true
	)
}
#endif
