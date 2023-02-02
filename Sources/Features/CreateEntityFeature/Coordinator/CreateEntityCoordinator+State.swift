import FeaturePrelude

// MARK: - CreateEntityCoordinator.State
public extension CreateEntityCoordinator {
	struct State: Sendable, Equatable {
		public enum Step: Sendable, Equatable {
			case step0_nameNewEntity(NameNewEntity<Entity>.State)
			case step1_selectGenesisFactorSource(SelectGenesisFactorSource.State)
			case step2_creationOfEntity(CreationOfEntity<Entity>.State)
			case step3_completion(NewEntityCompletion<Entity>.State)
		}

		public var step: Step
		public let config: CreateEntityConfig

		public init(
			config: CreateEntityConfig
		) {
			self.config = config
			self.step = .step0_nameNewEntity(.init(config: config))
		}
	}
}

// MARK: - CreateEntityNavigationButtonCTA
public enum CreateEntityNavigationButtonCTA: Sendable, Equatable {
	case goHome
	case goBackToChooseEntities

	public static let goBackToChooseAccounts: Self = .goBackToChooseAccounts
	public static let goBackToChoosePersonas: Self = .goBackToChooseAccounts
}

// MARK: - CreateEntityConfig
public struct CreateEntityConfig: Sendable, Equatable {
	public let specificNetworkID: NetworkID?
	public let isFirstEntity: Bool
	public let canBeDismissed: Bool
	public let navigationButtonCTA: CreateEntityNavigationButtonCTA

	public init(
		specificNetworkID: NetworkID? = nil,
		isFirstEntity: Bool,
		canBeDismissed: Bool,
		navigationButtonCTA: CreateEntityNavigationButtonCTA
	) {
		self.specificNetworkID = specificNetworkID
		self.isFirstEntity = isFirstEntity
		self.canBeDismissed = canBeDismissed
		self.navigationButtonCTA = navigationButtonCTA
	}
}
