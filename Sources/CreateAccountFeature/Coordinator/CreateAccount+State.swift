import ComposableArchitecture
import Profile

// MARK: - CreateAccount.State
public extension CreateAccount {
	struct State: Equatable {
		public var networkID: NetworkID
		public var numberOfExistingAccounts: Int
		public var accountName: String
		public var isValid: Bool
		@BindableState public var focusedField: Field?

		public init(
			networkID: NetworkID,
			numberOfExistingAccounts: Int = 0,
			accountName: String = "",
			isValid: Bool = false,
			focusedField: Field? = nil
		) {
			self.numberOfExistingAccounts = numberOfExistingAccounts
			self.accountName = accountName
			self.isValid = isValid
			self.focusedField = focusedField
			self.networkID = networkID
		}
	}
}

// MARK: - CreateAccount.State.Field
public extension CreateAccount.State {
	enum Field: String, Hashable {
		case accountName
	}
}
