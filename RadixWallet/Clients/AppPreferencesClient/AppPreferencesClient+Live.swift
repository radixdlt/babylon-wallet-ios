
// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			appPreferenceUpdates: {
				await profileStore.appPreferencesValues()
			},
			getPreferences: { await profileStore.profile.appPreferences },
			updatePreferences: { newPreferences in
				try await profileStore.updating {
					$0.appPreferences = newPreferences
				}
			},
			extractProfile: {
				await profileStore.profile
			},
			deleteProfileAndFactorSources: { keepInICloudIfPresent in
				try await profileStore.deleteProfile(keepInICloudIfPresent: keepInICloudIfPresent)
			},
			setIsCloudProfileSyncEnabled: { isEnabled in
				@Dependency(\.secureStorageClient) var secureStorageClient
				let profile = await profileStore.profile
				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
				guard wasEnabled != isEnabled else { return }

				try await profileStore.updating { profile in
					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
				}
				try secureStorageClient.updateIsCloudProfileSyncEnabled(
					profile.id,
					isEnabled ? .enable : .disable
				)
			},
			setIsCloudBackupEnabled: { isEnabled in
				let profile = await profileStore.profile
				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
				guard wasEnabled != isEnabled else { return }

				try await profileStore.updating { profile in
					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
				}
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
