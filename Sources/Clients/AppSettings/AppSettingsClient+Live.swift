import Dependencies
import Foundation
import UserDefaultsClient

// MARK: - AppSettingsClient + DependencyKey
extension AppSettingsClient: DependencyKey {
	static func live(
		initialSettingsToPersist: AppSettings? = .default
	) -> Self {
		let saveSettings: SaveSettings = { appSettings in
			@Dependency(\.userDefaultsClient) var userDefaultsClient

			do {
				let data = try JSONEncoder.iso8601.encode(appSettings)
				await userDefaultsClient.setData(data, Key.appSettings.rawValue)
			} catch {
				throw Error.saveSettingsFailed(reason: String(describing: error))
			}
		}

		let loadSettings: LoadSettings = {
			@Dependency(\.userDefaultsClient) var userDefaultsClient

			guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue) else {
				guard let settings = initialSettingsToPersist else {
					throw Error.loadSettingsFailed(reason: "Initial settings missing")
				}
				try await saveSettings(settings)
				return settings
			}

			do {
				let settings = try JSONDecoder().decode(AppSettings.self, from: data)
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

public extension AppSettingsClient {
	typealias Value = AppSettingsClient
	static let liveValue = AppSettingsClient.live()
}
