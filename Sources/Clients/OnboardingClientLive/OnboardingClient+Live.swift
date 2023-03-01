import ClientPrelude
import OnboardingClient
import ProfileStore

extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()
	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfile: {
				if let ephemeral = await profileStore.ephemeral {
					if let error = ephemeral.loadFailure {
						return .usersExistingProfileCouldNotBeLoaded(failure: error)
					} else {
						return .newUser
					}
				} else {
					return .existingProfileLoaded
				}

			},
			commitEphemeral: { try await profileStore.commitEphemeral() }
		)
	}
}
