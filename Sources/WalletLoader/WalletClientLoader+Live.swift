import Foundation
import KeychainClient
import Profile
import ProfileLoader
import WalletClient

public extension WalletClientLoader {
	static func live(
		keychainClient: KeychainClient = .live(),
		jsonDecoder: JSONDecoder = .iso8601
	) -> Self {
		Self.live(profileLoader: .live(keychainClient: keychainClient, jsonDecoder: jsonDecoder))
	}

	static func live(
		profileLoader: ProfileLoader
	) -> Self {
		Self(
			loadWalletClient: {
				let wallet = WalletClient.live
				if let profile = try await profileLoader.loadProfile() {
					wallet.injectProfile(profile)
				}
				return wallet
			}
		)
	}
}
