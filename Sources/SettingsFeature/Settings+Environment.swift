import Foundation
import KeychainClient
import Profile
import ProfileClient

public extension Settings {
	// MARK: Environment
	struct Environment {
		public let keychainClient: KeychainClient
		public let profileClient: ProfileClient

		public init(
			keychainClient: KeychainClient,
			profileClient: ProfileClient
		) {
			self.keychainClient = keychainClient
			self.profileClient = profileClient
		}
	}
}
