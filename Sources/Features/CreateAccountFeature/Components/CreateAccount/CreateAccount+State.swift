import FeaturePrelude
import GatherFactorsFeature

// MARK: - CreateAccount.State
public extension CreateAccount {
	struct State: Sendable, Equatable {
		public var onNetworkWithID: NetworkID?
		public var isFirstAccount: Bool
		public var inputtedAccountName: String
		public var sanitizedAccountName: String { inputtedAccountName.trimmed() }
		public var isCreatingAccount: Bool {
			gatherFactors != nil
		}

		public let shouldCreateProfile: Bool

		public var factorSources: FactorSources?
		public var gatherFactors: GatherFactors.State?

		@BindableState public var focusedField: Field?

		public init(
			onNetworkWithID: NetworkID? = nil,
			shouldCreateProfile: Bool = false,
			isFirstAccount: Bool = false,
			inputtedAccountName: String = "",
			focusedField: Field? = nil,
			factorSources: FactorSources? = nil,
			gatherFactors: GatherFactors.State? = nil
		) {
			self.onNetworkWithID = onNetworkWithID
			self.shouldCreateProfile = shouldCreateProfile
			self.inputtedAccountName = inputtedAccountName
			self.focusedField = focusedField
			self.factorSources = factorSources
			self.gatherFactors = gatherFactors
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
