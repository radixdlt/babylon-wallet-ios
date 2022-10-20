import Profile

// MARK: - ProfileLoader
public struct ProfileLoader {
	// FIXME: Decide which of these methods we are gonna use..
	public var loadProfileSnapshot: @Sendable () async throws -> ProfileSnapshot?
	public var loadProfile: @Sendable () async throws -> Profile?
}
