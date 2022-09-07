import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static func live(
		userDefaultsClient: UserDefaultsClient = .live(),
		defaultSettings: AppSettings = .defaults
	) -> Self {
		let saveSettings: SaveSettings = { appSettings in
			let data = try JSONEncoder().encode(appSettings)
			await userDefaultsClient.setData(data, Key.appSettings.rawValue)
		}

		let loadSettings: LoadSettings = {
			guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue)
			else {
				try await saveSettings(defaultSettings)
				return defaultSettings
			}
			return try JSONDecoder().decode(AppSettings.self, from: data)
		}

		return Self(
			saveSettings: saveSettings,
			loadSettings: loadSettings
		)
	}
}
