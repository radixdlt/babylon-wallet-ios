import ClientPrelude
import Profile

// MARK: - OnboardingClient
public struct OnboardingClient: Sendable {
	public var loadProfile: LoadProfile
	public var commitEphemeral: CommitEphemeral

	public init(
		loadProfile: @escaping LoadProfile,
		commitEphemeral: @escaping CommitEphemeral
	) {
		self.loadProfile = loadProfile
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
}
