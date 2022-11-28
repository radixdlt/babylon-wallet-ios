import Dependencies
import Foundation
import Profile
import Version

// MARK: - ProfileLoader
public struct ProfileLoader: Sendable, DependencyKey {
	public var loadProfile: @Sendable () async -> ProfileResult
}

// MARK: ProfileLoader.ProfileResult
public extension ProfileLoader {
	typealias ProfileResult = Swift.Result<Profile?, ProfileLoadingFailure>
}
