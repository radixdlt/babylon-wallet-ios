import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static func live(
		userDefaultsClient: UserDefaultsClient = .live(),
		initialSettingsToPersist: AppSettings? = .default
	) -> Self {
		let saveSettings: SaveSettings = { appSettings in
			do {
				let data = try JSONEncoder().encode(appSettings)
				await userDefaultsClient.setData(data, Key.appSettings.rawValue)
				print("save settings ✅, \(String(describing: appSettings))")
			} catch {
				throw Error.saveSettingsFailed(reason: String(describing: error))
			}
		}

		let loadSettings: LoadSettings = {
			guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue) else {
				guard let settings = initialSettingsToPersist else {
					throw Error.loadSettingsFailed(reason: "Initial settings missing")
				}
				try await saveSettings(settings)
				return settings
			}

			do {
				let settings = try JSONDecoder().decode(AppSettings.self, from: data)
				print("load settings ✅, \(String(describing: settings))")
				return settings
			} catch {
				throw Error.loadSettingsFailed(reason: String(describing: error))
			}
		}

		return Self(
			saveSettings: saveSettings,
			loadSettings: loadSettings
		)
	}
}
