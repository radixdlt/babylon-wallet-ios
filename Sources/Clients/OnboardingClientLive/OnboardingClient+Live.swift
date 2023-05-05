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
						.asyncCompactMap { header in
							try? await secureStorageClient.loadProfile(header.id)
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
