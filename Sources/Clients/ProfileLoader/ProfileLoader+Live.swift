import Dependencies
import Foundation
import JSON
import KeychainClientDependency
import Profile

// MARK: - ProfileLoader + DependencyKey
extension ProfileLoader: DependencyKey {
	public typealias Value = ProfileLoader
	public static let liveValue = Self(
		loadProfile: {
			@Dependency(\.keychainClient) var keychainClient
			@Dependency(\.jsonDecoder) var jsonDecoder
			guard let profile = try keychainClient.loadProfile(jsonDecoder: jsonDecoder()) else {
				return nil
			}
			guard (try? profile.perNetwork.onNetwork(id: .primary)) != nil else {
				try? keychainClient.removeAllFactorSourcesAndProfileSnapshot()
				return nil
			}
			return profile
		}
	)
}

// MARK: - ProfileLoader.Error
public extension ProfileLoader {
	enum Error: String, Swift.Error, Equatable {
		case failedToDecode
	}
}
