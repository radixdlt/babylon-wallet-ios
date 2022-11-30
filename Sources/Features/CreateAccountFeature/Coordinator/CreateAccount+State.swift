import ComposableArchitecture
import Profile

// MARK: - CreateAccount.State
public extension CreateAccount {
	struct State: Sendable, Equatable {
		public var numberOfExistingAccounts: Int
		public var accountName: String
		public var isValid: Bool
		public var isCreatingAccount: Bool
        public let shouldCreateProfile: Bool
		@BindableState public var focusedField: Field?

		public init(
            shouldCreateProfile: Bool,
			numberOfExistingAccounts: Int = 0,
			accountName: String = "",
			isValid: Bool = false,
			focusedField: Field? = nil,
			isCreatingAccount: Bool = false
		) {
            self.shouldCreateProfile = shouldCreateProfile
			self.numberOfExistingAccounts = numberOfExistingAccounts
			self.accountName = accountName
			self.isValid = isValid
			self.focusedField = focusedField
			self.isCreatingAccount = isCreatingAccount
		}
	}
}

// MARK: - CreateAccount.State.Field
public extension CreateAccount.State {
	enum Field: String, Sendable, Hashable {
		case accountName
	}
}
