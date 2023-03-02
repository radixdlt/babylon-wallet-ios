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
			commitEphemeral: { try await profileStore.commitEphemeral() },
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
			importProfileSnapshot: { try await profileStore.importProfileSnapshot($0) }
		)
	}
}
