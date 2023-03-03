import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var importProfileSnapshot: ImportProfileSnapshot
	public var loadEphemeralPrivateProfile: LoadEphemeralPrivateProfile
	public var commitEphemeral: CommitEphemeral

	public init(
		loadProfile: @escaping LoadProfile,
		importProfileSnapshot: @escaping ImportProfileSnapshot,
		loadEphemeralPrivateProfile: @escaping LoadEphemeralPrivateProfile,
		commitEphemeral: @escaping CommitEphemeral
	) {
		self.loadProfile = loadProfile
		self.importProfileSnapshot = importProfileSnapshot
		self.loadEphemeralPrivateProfile = loadEphemeralPrivateProfile
		self.commitEphemeral = commitEphemeral
	}
}

// MARK: - LoadProfileOutcome
public enum LoadProfileOutcome: Sendable, Hashable {
	case newUser
	case usersExistingProfileCouldNotBeLoaded(failure: Profile.LoadingFailure)
	case existingProfileLoaded
}

extension OnboardingClient {
	public typealias LoadProfile = @Sendable () async -> LoadProfileOutcome

	public typealias CommitEphemeral = @Sendable () async throws -> Void
	public typealias LoadEphemeralPrivateProfile = @Sendable () async throws -> Profile.Ephemeral.Private
	public typealias ImportProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
}
