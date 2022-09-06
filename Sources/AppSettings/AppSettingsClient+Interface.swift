import Common
import Foundation
import UserDefaultsClient

// MARK: - AppSettingsClient
public struct AppSettingsClient {
	var saveSettings: @Sendable (AppSettings) async throws -> Void
	var loadSettings: @Sendable () async throws -> AppSettings
}

// MARK: - Public Methods
public extension AppSettingsClient {
	func loadCurrency() async throws -> FiatCurrency {
		let settings = try await loadSettings()
		return settings.currency
	}

	func saveCurrency(currency: FiatCurrency) async throws {
		try await updating {
			$0.currency = currency
		}
	}

	func loadIsCurrencyAmountVisible() async throws -> Bool {
		let settings = try await loadSettings()
		return settings.isCurrencyAmountVisible
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

// MARK: - Private Types
extension AppSettingsClient {
	enum Key: String {
		case appSettings
	}
}
