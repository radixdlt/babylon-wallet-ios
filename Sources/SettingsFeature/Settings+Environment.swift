import Foundation
import KeychainClient
import Profile
import WalletClient

public extension Settings {
	// MARK: Environment
	struct Environment {
		public let keychainClient: KeychainClient
		public let walletClient: WalletClient

		public init(
			keychainClient: KeychainClient,
			walletClient: WalletClient
		) {
			self.keychainClient = keychainClient
			self.walletClient = walletClient
		}
	}
}
