import ComposableArchitecture
import SwiftUI

// MARK: - CreateAccountConfig
public struct CreateAccountConfig: Sendable, Hashable {
	public let specificNetworkID: NetworkID?
	public let isFirstAccount: Bool
	public let navigationButtonCTA: CreateAccountNavigationButtonCTA

	fileprivate init(
		isFirstAccount: Bool,
		navigationButtonCTA: CreateAccountNavigationButtonCTA,
		specificNetworkID: NetworkID? = nil
	) {
		self.specificNetworkID = specificNetworkID
		self.isFirstAccount = isFirstAccount
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
				navigationButtonCTA: .goHome
			)
		case let .firstAccountOnNewNetwork(specificNetworkID):
			self.init(
				isFirstAccount: true,
				navigationButtonCTA: .goBackToGateways,
				specificNetworkID: specificNetworkID
			)
		case .newAccountDuringDappInteraction:
			self.init(
				isFirstAccount: false,
				navigationButtonCTA: .goBackToChooseAccounts
			)
		case .newAccountFromHome:
			self.init(
				isFirstAccount: false,
				navigationButtonCTA: .goHome
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
