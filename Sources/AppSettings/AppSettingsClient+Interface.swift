import Common
import Foundation
import UserDefaultsClient

// MARK: - AppSettingsClient
public struct AppSettingsClient {
	public var saveSettings: SaveSettings
	public var loadSettings: LoadSettings

	public init(
		saveSettings: @escaping SaveSettings,
		loadSettings: @escaping LoadSettings
	) {
		self.saveSettings = saveSettings
		self.loadSettings = loadSettings
	}
}

// MARK: - Typealias
public extension AppSettingsClient {
	typealias SaveSettings = @Sendable (AppSettings) async throws -> Void
	typealias LoadSettings = @Sendable () async throws -> AppSettings
}

// MARK: - Public Methods
public extension AppSettingsClient {
	func saveCurrency(currency: FiatCurrency) async throws {
		try await updating {
			$0.currency = currency
		}
	}

	func saveIsCurrencyAmountVisible(_ isCurrencyAmountVisible: Bool) async throws {
		try await updating {
			$0.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Private Methods
private extension AppSettingsClient {
	func updating(_ modify: (inout AppSettings) -> Void) async throws {
		var settings = try await loadSettings()
		modify(&settings)
		try await saveSettings(settings)
	}
}

// MARK: AppSettingsClient.Error
public extension AppSettingsClient {
	enum Error: Swift.Error, LocalizedError {
		case loadSettingsFailed(reason: String)
		case saveSettingsFailed(reason: String)
	}
}

// MARK: AppSettingsClient.Key
extension AppSettingsClient {
	enum Key: String {
		case appSettings
	}
}
