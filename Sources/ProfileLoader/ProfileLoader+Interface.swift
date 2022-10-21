import Profile

// MARK: - ProfileLoader
public struct ProfileLoader {
	public var loadProfile: @Sendable () async throws -> Profile?
}
