import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var loadProfileBackups: LoadProfileBackups
	public var importProfileSnapshot: ImportProfileSnapshot
	public var commitEphemeral: CommitEphemeral

	public init(
		loadProfile: @escaping LoadProfile,
		loadProfileBackups: @escaping LoadProfileBackups,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		commitEphemeral: @escaping CommitEphemeral
	) {
		self.loadProfile = loadProfile
		self.loadProfileBackups = loadProfileBackups
		self.importProfileSnapshot = importProfileSnapshot
		self.commitEphemeral = commitEphemeral
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> LoadProfileOutcome
	public typealias LoadProfileBackups = @Sendable () async -> NonEmpty<IdentifiedArrayOf<Profile>>?

	public typealias CommitEphemeral = @Sendable () async throws -> Void
	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
}
