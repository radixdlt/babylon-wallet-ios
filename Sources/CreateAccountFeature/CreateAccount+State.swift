import ComposableArchitecture

// MARK: CreateAccount.State
public extension CreateAccount {
	struct State: Equatable {
		public var accountName: String
		public var isValid: Bool

		public init(
			accountName: String = "",
			isValid: Bool = false
		) {
			self.accountName = accountName
			self.isValid = isValid
		}
	}
}
