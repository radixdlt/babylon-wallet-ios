import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var loadProfileBackups: LoadProfileBackups
	public var importProfileSnapshot: ImportProfileSnapshot
	public var importCloudProfile: ImportCloudProfile
	public var commitEphemeral: CommitEphemeral
	public var loadDeviceID: LoadDeviceID

	public init(
		loadProfile: @escaping LoadProfile,
		loadProfileBackups: @escaping LoadProfileBackups,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		importCloudProfile: @escaping ImportCloudProfile,
		commitEphemeral: @escaping CommitEphemeral,
		loadDeviceID: @escaping LoadDeviceID
	) {
		self.loadProfile = loadProfile
		self.loadProfileBackups = loadProfileBackups
		self.importProfileSnapshot = importProfileSnapshot
		self.importCloudProfile = importCloudProfile
		self.commitEphemeral = commitEphemeral
		self.loadDeviceID = loadDeviceID
	}
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> LoadProfileOutcome
	public typealias LoadProfileBackups = @Sendable () async -> ProfileSnapshot.HeaderList?

	public typealias CommitEphemeral = @Sendable () async throws -> Void
	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
	public typealias ImportCloudProfile = @Sendable (ProfileSnapshot.Header) async throws -> Void

	public typealias LoadDeviceID = @Sendable () async -> UUID?
}
