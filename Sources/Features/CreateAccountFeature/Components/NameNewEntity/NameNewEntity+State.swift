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

		public var factorSources: FactorSources?
		public var genesisFactorSource: FactorSource?
		public var gatherFactor: GatherFactor<GatherFactorPurposeDerivePublicKey>.State?

		@BindableState public var focusedField: Field?

		public init(
			//			onNetworkWithID: NetworkID? = nil,
//			shouldCreateProfile: Bool = false,
			isFirstAccount: Bool = false,
			inputtedAccountName: String = "",
			focusedField: Field? = nil,
			factorSources: FactorSources? = nil,
			genesisFactorSource: FactorSource? = nil,
			gatherFactor: GatherFactor<GatherFactorPurposeDerivePublicKey>.State? = nil
		) {
//			self.onNetworkWithID = onNetworkWithID
//			self.shouldCreateProfile = shouldCreateProfile
			self.inputtedName = inputtedAccountName
			self.focusedField = focusedField
			self.factorSources = factorSources
			self.genesisFactorSource = genesisFactorSource
			self.gatherFactor = gatherFactor
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
