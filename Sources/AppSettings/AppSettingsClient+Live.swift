import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static func live(userDefaultsClient: UserDefaultsClient = .live()) -> Self {
		Self(
			saveSettings: { appSettings in
				guard let data = try? JSONEncoder().encode(appSettings) else {
					print("Error saving settings")
					return
				}
				await userDefaultsClient.setData(data, Key.appSettings.rawValue)
			}, loadSettings: {
				guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue),
				      let appSettings = try? JSONDecoder().decode(AppSettings.self, from: data)
				else {
					print("Error loading settings")
					return .defaults
				}
				return appSettings
			}
		)
	}
}
