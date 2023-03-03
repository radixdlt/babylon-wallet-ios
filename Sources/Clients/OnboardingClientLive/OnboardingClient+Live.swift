import ClientPrelude
import OnboardingClient
import ProfileStore

extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()
	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadProfile: {
				if let ephemeral = await profileStore.getEphemeral() {
					if let error = ephemeral.loadFailure {
						return .usersExistingProfileCouldNotBeLoaded(failure: error)
					} else {
						return .newUser
					}
				} else {
					return .existingProfileLoaded
				}

			},
			importProfileSnapshot: { try await profileStore.importProfileSnapshot($0) },
			loadEphemeralPrivateProfile: {
				guard let ephemeralPrivateProfile = await profileStore.getEphemeral() else {
					struct ExpectedEphemeralButWasNot: Swift.Error {}
					throw ExpectedEphemeralButWasNot()
				}
				return ephemeralPrivateProfile.private
			},
			commitEphemeral: {
				try await profileStore.commitEphemeral()
			}
		)
	}
}
