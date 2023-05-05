import ClientPrelude
import OnboardingClient
import ProfileStore

extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			loadProfile: {
				await getProfileStore().getLoadProfileOutcome()
			},
			loadProfileBackups: {
				do {
					let backupProfiles = try await secureStorageClient
						.loadProfileHeaderList()?
						.asyncCompactMap { header -> Profile? in
							guard let profile = try? await secureStorageClient.loadProfile(header.id) else {
								return nil
							}
							do {
								try profile.header.validateCompatibility()
								return profile
							} catch {
								// delete obsolete profile
								return nil
							}
						}

					return backupProfiles.flatMap {
						.init(rawValue: .init(uncheckedUniqueElements: $0))
					}
				} catch {
					try? await secureStorageClient.deleteProfileHeaderList()
					return nil
				}

			},
			importProfileSnapshot: {
				try await getProfileStore().importProfileSnapshot($0)
			},
			commitEphemeral: {
				try await getProfileStore().commitEphemeral()
			}
		)
	}
}
