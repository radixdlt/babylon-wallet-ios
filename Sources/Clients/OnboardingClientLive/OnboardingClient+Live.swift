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
					assertionFailure("Corrupt Profile headers")
					loggerGlobal.critical("Corrupt Profile header: \(error.legibleLocalizedDescription)")
					// Corrupt Profile Headers, delete
					_ = try? await secureStorageClient.deleteProfileHeaderList()
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
