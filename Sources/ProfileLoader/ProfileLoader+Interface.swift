import Profile

// MARK: - ProfileLoader
public struct ProfileLoader {
	public var loadProfileSnapshot: @Sendable () async throws -> ProfileSnapshot?
}
