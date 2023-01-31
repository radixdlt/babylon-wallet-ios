import FeaturePrelude
import GatherFactorsFeature

// MARK: - NameNewEntity.State
public extension NameNewEntity {
	struct State: Sendable, Equatable {
//		public var onNetworkWithID: NetworkID?
		public var isFirst: Bool
		public var inputtedName: String
		public var sanitizedName: String { inputtedName.trimmed() }
//		public var isCreatingAccount: Bool {
//			gatherFactor != nil
//		}

//		public let shouldCreateProfile: Bool

		@BindingState public var focusedField: Field?

		public init(
			//			onNetworkWithID: NetworkID? = nil,
//			shouldCreateProfile: Bool = false,
			isFirstAccount: Bool = false,
			inputtedAccountName: String = "",
			focusedField: Field? = nil
		) {
//			self.onNetworkWithID = onNetworkWithID
//			self.shouldCreateProfile = shouldCreateProfile
			self.inputtedName = inputtedAccountName
			self.focusedField = focusedField
			self.isFirst = isFirstAccount
		}
	}
}

// MARK: - NameNewEntity.State.Field
public extension NameNewEntity.State {
	enum Field: String, Sendable, Hashable {
		case accountName
	}
}
