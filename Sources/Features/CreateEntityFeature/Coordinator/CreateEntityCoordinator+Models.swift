import FeaturePrelude

// MARK: - CreateEntityConfig
public struct CreateEntityConfig: Sendable, Hashable {
	public let specificNetworkID: NetworkID?
	public let isFirstEntity: Bool
	public let canBeDismissed: Bool
	public let navigationButtonCTA: CreateEntityNavigationButtonCTA

	fileprivate init(
		isFirstEntity: Bool,
		canBeDismissed: Bool,
		navigationButtonCTA: CreateEntityNavigationButtonCTA,
		specificNetworkID: NetworkID? = nil
	) {
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

extension CreateEntityConfig {
	public init(purpose: CreateEntityPurpose) {
		switch purpose {
		case .firstAccountForNewProfile:
			self.init(
				isFirstEntity: true,
				canBeDismissed: false,
				navigationButtonCTA: .goHome,
				specificNetworkID: nil
			)
		case let .firstAccountOnNewNetwork(specificNetworkID):
			self.init(
				isFirstEntity: false,
				canBeDismissed: false,
				navigationButtonCTA: .goHome,
				specificNetworkID: specificNetworkID
			)
		case .newAccountDuringDappInteraction:
			self.init(
				isFirstEntity: false,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToChooseAccounts,
				specificNetworkID: nil
			)
		case let .newPersonaDuringDappInteract(isFirst):
			self.init(
				isFirstEntity: isFirst,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToPersonaList,
				specificNetworkID: nil
			)
		case .newAccountFromHome:
			self.init(
				isFirstEntity: false,
				canBeDismissed: true,
				navigationButtonCTA: .goHome,
				specificNetworkID: nil
			)
		}
	}
}

// MARK: - CreateEntityPurpose
public enum CreateEntityPurpose {
	case firstAccountForNewProfile
	case firstAccountOnNewNetwork(NetworkID)
	case newAccountDuringDappInteraction
	case newPersonaDuringDappInteract(isFirst: Bool)
	case newAccountFromHome
}
