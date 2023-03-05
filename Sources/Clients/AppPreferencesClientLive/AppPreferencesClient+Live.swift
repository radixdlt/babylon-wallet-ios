import AppPreferencesClient
import ClientPrelude
import ProfileStore

// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await ProfileStore.shared() }
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
			deleteProfileAndFactorSources: {
				try await getProfileStore().deleteProfile()
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
