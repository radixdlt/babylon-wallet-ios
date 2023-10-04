import EngineKit
import FeaturePrelude

// MARK: - CreateAccountConfig
public struct CreateAccountConfig: Sendable, Hashable {
	public let specificNetworkID: NetworkID?
	public let isFirstAccount: Bool
	public let canBeDismissed: Bool
	public let navigationButtonCTA: CreateAccountNavigationButtonCTA

	fileprivate init(
		isFirstAccount: Bool,
		canBeDismissed: Bool,
		navigationButtonCTA: CreateAccountNavigationButtonCTA,
		specificNetworkID: NetworkID? = nil
	) {
		self.specificNetworkID = specificNetworkID
		self.isFirstAccount = isFirstAccount
		self.canBeDismissed = canBeDismissed
		self.navigationButtonCTA = navigationButtonCTA
	}
}

// MARK: - CreateAccountNavigationButtonCTA
public enum CreateAccountNavigationButtonCTA: Sendable, Equatable {
	case goHome
	case goBackToChooseAccounts
	case goBackToGateways
}

extension CreateAccountConfig {
	public init(purpose: CreateAccountPurpose) {
		switch purpose {
		case .firstAccountForNewProfile:
			self.init(
				isFirstAccount: true,
				canBeDismissed: false,
				navigationButtonCTA: .goHome,
				specificNetworkID: nil
			)
		case let .firstAccountOnNewNetwork(specificNetworkID):
			self.init(
				isFirstAccount: true,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToGateways,
				specificNetworkID: specificNetworkID
			)
		case .newAccountDuringDappInteraction:
			self.init(
				isFirstAccount: false,
				canBeDismissed: true,
				navigationButtonCTA: .goBackToChooseAccounts,
				specificNetworkID: nil
			)

		case .newAccountFromHome:
			self.init(
				isFirstAccount: false,
				canBeDismissed: true,
				navigationButtonCTA: .goHome,
				specificNetworkID: nil
			)
		}
	}
}

// MARK: - CreateAccountPurpose
public enum CreateAccountPurpose {
	case firstAccountForNewProfile
	case firstAccountOnNewNetwork(NetworkID)
	case newAccountDuringDappInteraction
	case newAccountFromHome
}
