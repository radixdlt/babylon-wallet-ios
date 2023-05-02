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

				guard let change = try await (getProfileStore().updating { profile -> CloudProfileSyncActivation? in
					let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
					switch (wasEnabled.rawValue, isEnabled.rawValue) {
					case (false, false): return nil
					case (true, true): return nil
					case (true, false): return .disable
					case (false, true): return .enable
					}
				}) else {
					return
				}

				try await secureStorageClient.updateIsCloudProfileSyncEnabled(change)
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
