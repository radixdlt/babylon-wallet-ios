import FeaturePrelude

// MARK: - CreateAccount.State
public extension CreateAccount {
	struct State: Sendable, Equatable {
		public var onNetworkWithID: NetworkID?
		public var isFirstAccount: Bool
		public var inputtedAccountName: String
		public var sanitizedAccountName: String { inputtedAccountName.trimmed() }
		public var isCreatingAccount: Bool
		public let shouldCreateProfile: Bool
		@BindableState public var focusedField: Field?

		public init(
			onNetworkWithID: NetworkID? = nil,
			shouldCreateProfile: Bool = false,
			isFirstAccount: Bool = false,
			inputtedAccountName: String = "",
			focusedField: Field? = nil,
			isCreatingAccount: Bool = false
		) {
			self.onNetworkWithID = onNetworkWithID
			self.shouldCreateProfile = shouldCreateProfile
			self.inputtedAccountName = inputtedAccountName
			self.focusedField = focusedField
			self.isCreatingAccount = isCreatingAccount
			self.isFirstAccount = isFirstAccount
		}
	}
}

// MARK: - CreateAccount.State.Field
public extension CreateAccount.State {
	enum Field: String, Sendable, Hashable {
		case accountName
	}
}
