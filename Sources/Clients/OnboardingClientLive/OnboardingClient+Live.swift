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
			createAccountInEphemeralProfile: { _ in
				guard var ephemeralPrivateProfile = await profileStore.getEphemeral() else {
					struct ExpectedEphemeralButWasNot: Swift.Error {}
					throw ExpectedEphemeralButWasNot()
				}
				ephemeralPrivateProfile?.private.profile
				/*
				 createUnsavedVirtualEntity: { request in
				     let profile = await profileStore.profile
				     return try await profile.createNewUnsavedVirtualEntity(request: request)
				 },
				 saveNewVirtualEntity: { entity in
				     switch entity.kind {
				     case .account:
				         try await profileStore.updating {
				             try $0.addAccount(entity.cast())
				         }
				     case .identity:
				         try await profileStore.updating {
				             try $0.addPersona(entity.cast())
				         }
				     }
				 },
				 */
			},
			commitEphemeral: {
				try await profileStore.commitEphemeral()
			}
		)
	}
}
