
// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			appPreferenceUpdates: {
				await profileStore.appPreferencesValues()
			},
			getPreferences: { await profileStore.profileSequence().first().appPreferences },
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

	public static let liveValue: Self = .live()
}
