
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
			deleteProfileAndFactorSources: { keepInICloudIfPresent in
				try await getProfileStore().deleteProfile(keepInICloudIfPresent: keepInICloudIfPresent)
			},
			setIsCloudProfileSyncEnabled: { isEnabled in
				@Dependency(\.secureStorageClient) var secureStorageClient
				let profile = await getProfileStore().profile
				let wasEnabled = profile.appPreferences.security.isCloudProfileSyncEnabled
				guard wasEnabled != isEnabled else { return }

				try await getProfileStore().updating { profile in
					profile.appPreferences.security.isCloudProfileSyncEnabled = isEnabled
				}
				try await secureStorageClient.updateIsCloudProfileSyncEnabled(
					profile.id,
					isEnabled ? .enable : .disable
				)
			},
			getDetailsOfSecurityStructure: { configRef in
				try await getProfileStore().profile.detailedSecurityStructureConfiguration(reference: configRef)
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
