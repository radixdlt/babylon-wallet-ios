
// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			appPreferenceUpdates: {
				await profileStore.appPreferencesValues()
			},
			getPreferences: { await profileStore.profile().appPreferences },
			updatePreferences: { newPreferences in
				try await profileStore.updating {
					$0.appPreferences = newPreferences
				}
			},
			extractProfile: {
				await profileStore.profile()
			},
			deleteProfileAndFactorSources: {
				try await profileStore.deleteProfile()
			},
			setIsCloudBackupEnabled: { isEnabled in
				let profile = await profileStore.profile()
				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
				guard wasEnabled != isEnabled else { return }

				try await profileStore.updating { profile in
					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
				}
			}
		)
	}

	static let liveValue: Self = .live()
}
