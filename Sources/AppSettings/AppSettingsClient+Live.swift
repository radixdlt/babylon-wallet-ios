import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static func live(userDefaultsClient: UserDefaultsClient = .live()) -> Self {
		Self(
			saveSettings: { appSettings in
				guard let data = try? JSONEncoder().encode(appSettings) else {
					throw (AppSettingsClientError.saveSettingsFailed)
				}
				await userDefaultsClient.setData(data, Key.appSettings.rawValue)
			}, loadSettings: {
				guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue),
				      let appSettings = try? JSONDecoder().decode(AppSettings.self, from: data)
				else {
					throw (AppSettingsClientError.loadSettingsFailed)
				}
				return appSettings
			}
		)
	}
}
