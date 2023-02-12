import ClientPrelude

// MARK: - AppSettingsClient
public struct AppSettingsClient: Sendable {
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
extension AppSettingsClient {
	public typealias SaveSettings = @Sendable (AppSettings) async throws -> Void
	public typealias LoadSettings = @Sendable () async throws -> AppSettings
}

// MARK: - Public Methods
extension AppSettingsClient {
	public func saveCurrency(currency: FiatCurrency) async throws {
		try await updating {
			$0.currency = currency
		}
	}

	public func saveIsCurrencyAmountVisible(_ isCurrencyAmountVisible: Bool) async throws {
		try await updating {
			$0.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Private Methods
extension AppSettingsClient {
	private func updating(_ modify: (inout AppSettings) -> Void) async throws {
		var settings = try await loadSettings()
		modify(&settings)
		try await saveSettings(settings)
	}
}

// MARK: AppSettingsClient.Error
extension AppSettingsClient {
	public enum Error: Swift.Error, LocalizedError {
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

extension DependencyValues {
	public var appSettingsClient: AppSettingsClient {
		get { self[AppSettingsClient.self] }
		set { self[AppSettingsClient.self] = newValue }
	}
}
