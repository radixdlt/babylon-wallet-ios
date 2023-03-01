import AppPreferencesClient
import ClientPrelude
import ProfileStore

// MARK: - AppPreferencesClient + DependencyKey
extension AppPreferencesClient: DependencyKey {
	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			loadPreferences: { await profileStore.profile.appPreferences },
			savePreferences: { newPreferences in
				try await profileStore.updating {
					$0.appPreferences = newPreferences
				}
			},
			extractProfileSnapshot: {
				await profileStore.profile.snapshot()
			},
			deleteProfileAndFactorSources: {
				try await profileStore.deleteProfile()
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
