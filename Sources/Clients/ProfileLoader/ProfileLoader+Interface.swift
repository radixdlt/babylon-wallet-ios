import Foundation
import Prelude
import Profile
import Version

// MARK: - ProfileLoader
public struct ProfileLoader: Sendable, DependencyKey {
	public typealias LoadProfile = @Sendable () async -> ProfileResult

	public var loadProfile: LoadProfile

	public init(loadProfile: @escaping LoadProfile) {
		self.loadProfile = loadProfile
	}
}

// MARK: ProfileLoader.ProfileResult
public extension ProfileLoader {
	typealias ProfileResult = Swift.Result<Profile?, ProfileLoadingFailure>
}
