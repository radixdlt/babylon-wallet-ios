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

// MARK: - Public Types
public extension AppSettingsClient {
	enum ClientError: Error, LocalizedError {
		case loadSettingsFailed
		case saveSettingsFailed
	}
}

// MARK: - Internal Types
extension AppSettingsClient {
	enum Key: String {
		case appSettings
	}
}
