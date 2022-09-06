import Common
import Foundation
import UserDefaultsClient

// MARK: - AppSettingsClient
public struct AppSettingsClient {
	public let userDefaultsClient: UserDefaultsClient

	public init(
		userDefaultsClient: UserDefaultsClient = .live()
	) {
		self.userDefaultsClient = userDefaultsClient
	}
}

// MARK: - Public Methods
public extension AppSettingsClient {
	func saveCurrency(_ currency: FiatCurrency) async {
		var appSettings = loadSettings()
		appSettings.currency = currency
		await saveSettings(appSettings)
	}

	func loadCurrency() -> FiatCurrency {
		let appSettings = loadSettings()
		return appSettings.currency
	}

	func saveIsCurrencyAmountVisible(_ value: Bool) async {
		var appSettings = loadSettings()
		appSettings.isCurrencyAmountVisible = value
		await saveSettings(appSettings)
	}

	func loadIsCurrencyAmountVisible() -> Bool {
		let appSettings = loadSettings()
		return appSettings.isCurrencyAmountVisible
	}

	private func loadSettings() -> AppSettings {
		guard let data = userDefaultsClient.dataForKey(Key.appSettings.rawValue),
		      let appSettings = try? JSONDecoder().decode(AppSettings.self, from: data)
		else {
			print("Error loading settings")
			return .defaults
		}
		return appSettings
	}

	private func saveSettings(_ appSettings: AppSettings) async {
		guard let data = try? JSONEncoder().encode(appSettings) else {
			print("Error loading settings")
			return
		}
		await userDefaultsClient.setData(data, Key.appSettings.rawValue)
	}
}

// MARK: - Private Methods
private extension AppSettingsClient {
	enum Key: String {
		case appSettings
	}
}
