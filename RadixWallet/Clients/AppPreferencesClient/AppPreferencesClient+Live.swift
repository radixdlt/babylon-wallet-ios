
// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		Self(
			appPreferenceUpdates: {
//				await profileStore.appPreferencesValues()
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			getPreferences: {
//				await profileStore.profile.appPreferences
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			updatePreferences: { _ in
//				try await profileStore.updating {
//					$0.appPreferences = newPreferences
//				}
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			extractProfileSnapshot: {
//				await profileStore.profile.snapshot()
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			deleteProfileAndFactorSources: { _ in
//				try await profileStore.deleteProfile(keepInICloudIfPresent: keepInICloudIfPresent)
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			setIsCloudProfileSyncEnabled: { _ in
//				@Dependency(\.secureStorageClient) var secureStorageClient
//				let profile = await profileStore.profile
//				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
//				guard wasEnabled != isEnabled else { return }
//
//				try await profileStore.updating { profile in
//					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
//				}
//				try secureStorageClient.updateIsCloudProfileSyncEnabled(
//					profile.id,
//					isEnabled ? .enable : .disable
//				)
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
