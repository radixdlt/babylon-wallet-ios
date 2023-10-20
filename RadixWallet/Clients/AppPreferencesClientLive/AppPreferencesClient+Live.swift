
// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			getPreferences: { await profileStore.profile.appPreferences },
			updatePreferences: { newPreferences in
				try await profileStore.updating {
					$0.appPreferences = newPreferences
				}
			},
			extractProfileSnapshot: {
				await profileStore.profile.snapshot()
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
			getDetailsOfSecurityStructure: { configRef in
				try await profileStore.profile.detailedSecurityStructureConfiguration(reference: configRef)
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
