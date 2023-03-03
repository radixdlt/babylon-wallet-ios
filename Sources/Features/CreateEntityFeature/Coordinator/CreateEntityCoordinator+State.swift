import FeaturePrelude

// MARK: - CreateEntityCoordinator.State
extension CreateEntityCoordinator {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case step0_nameNewEntity(NameNewEntity<Entity>.State)
			case step1_selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(NewEntityCompletion<Entity>.State)
		}

		public var step: Step
		public let config: CreateEntityConfig

		public init(
			step: Step? = nil,
			config: CreateEntityConfig
		) {
			self.config = config
			self.step = step ?? .step0_nameNewEntity(.init(config: config))
		}
	}
}

extension CreateEntityCoordinator.State {
	var shouldDisplayNavBar: Bool {
		guard
			config.canBeDismissed
		else { return false }
		switch step {
		case .step0_nameNewEntity, .step1_selectGenesisFactorSource: return true
		case .step2_creationOfEntity, .step3_completion: return false
		}
	}
}

// MARK: - CreateEntityNavigationButtonCTA
public enum CreateEntityNavigationButtonCTA: Sendable, Equatable {
	case goHome
	case goBackToPersonaList
	case goBackToChooseEntities

	public static let goBackToChooseAccounts: Self = .goBackToChooseEntities
	public static let goBackToChoosePersonas: Self = .goBackToChooseEntities
}

// MARK: - CreateEntityConfig
public struct CreateEntityConfig: Sendable, Hashable {
	// N.B. this will have to be non nil if this CreateEntity flow
	// was triggered as part NewProfileThenAccount flow (part of onboarding), since
	// we will have created a new factor
	public let specificGenesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy?

	public let specificNetworkID: NetworkID?
	public let isFirstEntity: Bool
	public let canBeDismissed: Bool
	public let navigationButtonCTA: CreateEntityNavigationButtonCTA

	public init(
		specificGenesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy? = nil,
		specificNetworkID: NetworkID? = nil,
		isFirstEntity: Bool,
		canBeDismissed: Bool,
		navigationButtonCTA: CreateEntityNavigationButtonCTA
	) {
		self.specificGenesisFactorInstanceDerivationStrategy = specificGenesisFactorInstanceDerivationStrategy
		self.specificNetworkID = specificNetworkID
		self.isFirstEntity = isFirstEntity
		self.canBeDismissed = canBeDismissed
		self.navigationButtonCTA = navigationButtonCTA
	}
}
