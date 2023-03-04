import FeaturePrelude

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

// MARK: - CreateEntityNavigationButtonCTA
public enum CreateEntityNavigationButtonCTA: Sendable, Equatable {
	case goHome
	case goBackToPersonaList
	case goBackToChooseEntities

	public static let goBackToChooseAccounts: Self = .goBackToChooseEntities
	public static let goBackToChoosePersonas: Self = .goBackToChooseEntities
}
