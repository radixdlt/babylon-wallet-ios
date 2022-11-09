import Dependencies
import Foundation
import JSON
import KeychainClientDependency

// MARK: - ProfileLoader + DependencyKey
extension ProfileLoader: DependencyKey {
	public typealias Value = ProfileLoader
	public static let liveValue = Self(
		loadProfile: {
			@Dependency(\.keychainClient) var keychainClient
			@Dependency(\.jsonDecoder) var jsonDecoder
			return try keychainClient.loadProfile(jsonDecoder: jsonDecoder)
		}
	)
}

// MARK: - ProfileLoader.Error
public extension ProfileLoader {
	enum Error: String, Swift.Error, Equatable {
		case failedToDecode
	}
}
