import AppPreferencesClient
import ClientPrelude
import ProfileStore
import SecureStorageClient

// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		Self(
			getPreferences: { await getProfileStore().profile.appPreferences },
			updatePreferences: { newPreferences in
				try await getProfileStore().updating {
					$0.appPreferences = newPreferences
				}
			},
			extractProfileSnapshot: {
				await getProfileStore().profile.snapshot()
			},
			deleteProfileAndFactorSources: { keepIcloudIfPresent in
				try await getProfileStore().deleteProfile(keepIcloudIfPresent: keepIcloudIfPresent)
			},
			setIsCloudProfileSyncEnabled: { isEnabled in
				@Dependency(\.secureStorageClient) var secureStorageClient
				let profile = await getProfileStore().profile
				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled

				switch (wasEnabled, isEnabled) {
				case (false, false), (true, true): return // Do not update if no change
				case (true, false), (false, true):
					try await getProfileStore().updating { profile in
						profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
					}
					try await secureStorageClient.updateIsCloudProfileSyncEnabled(
						profile.id,
						isEnabled ? .enable : .disable
					)
				}
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
