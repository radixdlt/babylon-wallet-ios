import ComposableArchitecture
import SwiftUI

// MARK: - CreateAccountConfig
struct CreateAccountConfig: Sendable, Hashable {
	let specificNetworkID: NetworkID?
	let isFirstAccount: Bool
	let isNewProfile: Bool
	let navigationButtonCTA: CreateAccountNavigationButtonCTA

	fileprivate init(
		isFirstAccount: Bool,
		isNewProfile: Bool = false,
		navigationButtonCTA: CreateAccountNavigationButtonCTA,
		specificNetworkID: NetworkID? = nil
	) {
		self.specificNetworkID = specificNetworkID
		self.isFirstAccount = isFirstAccount
		self.isNewProfile = isNewProfile
		self.navigationButtonCTA = navigationButtonCTA
	}
}

// MARK: - CreateAccountNavigationButtonCTA
enum CreateAccountNavigationButtonCTA: Sendable, Equatable {
	case goHome
	case goBackToChooseAccounts
	case goBackToGateways
}

extension CreateAccountConfig {
	init(purpose: CreateAccountPurpose) {
		switch purpose {
		case .firstAccountForNewProfile:
			self.init(
				isFirstAccount: true,
				isNewProfile: true,
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
enum CreateAccountPurpose {
	case firstAccountForNewProfile
	case firstAccountOnNewNetwork(NetworkID)
	case newAccountDuringDappInteraction
	case newAccountFromHome
}
