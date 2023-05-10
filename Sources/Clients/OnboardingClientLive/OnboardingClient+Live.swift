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
					return try await secureStorageClient.loadProfileHeaderList()
				} catch {
					// Corupt Profile Headers, delete
					try? await secureStorageClient.deleteProfileHeaderList()
					return nil
				}
			},
			importProfileSnapshot: {
				try await getProfileStore().importProfileSnapshot($0)
			},
			importCloudProfile: { header in
				try await getProfileStore().importCloudProfileSnapshot(header)
			},
			commitEphemeral: {
				try await getProfileStore().commitEphemeral()
			}
		)
	}
}
