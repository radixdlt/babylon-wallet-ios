import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var importProfileSnapshot: ImportProfileSnapshot
	public var commitEphemeral: CommitEphemeral

	public init(
		loadProfile: @escaping LoadProfile,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		commitEphemeral: @escaping CommitEphemeral
	) {
		self.loadProfile = loadProfile
		self.importProfileSnapshot = importProfileSnapshot
		self.commitEphemeral = commitEphemeral
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> LoadProfileOutcome

	public typealias CommitEphemeral = @Sendable () async throws -> Void
	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
}
