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
			setIsIcloudProfileSyncEnabled: { isEnabled in
				@Dependency(\.secureStorageClient) var secureStorageClient
				enum Action {
					case none
					case removeProfileFromIcloudIfNeeded
					case addProfileToIcloud
				}
				let action = try await getProfileStore().updating { profile -> Action in
					let wasEnabled = profile.appPreferences.security.iCloudProfileSyncEnabled
					profile.appPreferences.security.iCloudProfileSyncEnabled = isEnabled
					switch (wasEnabled.rawValue, isEnabled.rawValue) {
					case (false, false): return .none
					case (true, true): return .none
					case (true, false): return .removeProfileFromIcloudIfNeeded
					case (false, true): return .addProfileToIcloud
					}
				}
				switch action {
				case .none: return
				case .addProfileToIcloud:
					try await secureStorageClient.setIsIcloudProfileSyncEnabled(true)
				case .removeProfileFromIcloudIfNeeded:
					try await secureStorageClient.setIsIcloudProfileSyncEnabled(false)
				}
			}
		)
	}

	public typealias Value = AppPreferencesClient
	public static let liveValue: Self = .live()
}
