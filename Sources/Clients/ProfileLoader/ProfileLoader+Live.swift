import Foundation
import KeychainClient
import Profile

public extension ProfileLoader {
	static func live(
		keychainClient: KeychainClient,
		jsonDecoder: JSONDecoder = .iso8601
	) -> Self {
		Self(
			loadProfile: {
				try keychainClient.loadProfile(jsonDecoder: jsonDecoder)
			}
		)
	}
}

// MARK: - ProfileLoader.Error
public extension ProfileLoader {
	enum Error: String, Swift.Error, Equatable {
		case failedToDecode
	}
}
