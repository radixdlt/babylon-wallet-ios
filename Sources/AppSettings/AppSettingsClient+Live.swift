import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static func live(
		userDefaultsClient: UserDefaultsClient = .live(),
		initialSettingsToPersist: AppSettings? = .default
	) -> Self {
		let saveSettings: SaveSettings = { appSettings in
			let data = try JSONEncoder().encode(appSettings)
			await userDefaultsClient.setData(data, Key.appSettings.rawValue)
		}

		let loadSettings: LoadSettings = {
			guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue)
			else {
				guard let settings = initialSettingsToPersist else {
					throw AppSettingsClient.Error.loadSettingsFailed
				}
				try await saveSettings(settings)
				return settings
			}
			return try JSONDecoder().decode(AppSettings.self, from: data)
		}

		return Self(
			saveSettings: saveSettings,
			loadSettings: loadSettings
		)
	}
}
