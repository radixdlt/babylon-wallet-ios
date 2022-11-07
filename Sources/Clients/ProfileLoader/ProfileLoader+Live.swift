import Dependencies
import Foundation
import KeychainClientDependency

public extension ProfileLoader {
	static func live(
		jsonDecoder: JSONDecoder = .iso8601
	) -> Self {
		Self(
			loadProfile: {
				@Dependency(\.keychainClient) var keychainClient
				return try keychainClient.loadProfile(jsonDecoder: jsonDecoder)
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
