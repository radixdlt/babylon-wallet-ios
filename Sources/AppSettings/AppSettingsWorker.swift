import Common
import Foundation
import UserDefaultsClient

// MARK: - AppSettingsWorker
public struct AppSettingsWorker {
	public let userDefaultsClient: UserDefaultsClient

	public init(
		userDefaultsClient: UserDefaultsClient = .live()
	) {
		self.userDefaultsClient = userDefaultsClient
	}
}

// MARK: - Public Methods
public extension AppSettingsWorker {
	func loadCurrency() -> FiatCurrency {
		// TODO: implement
		.gbp
	}

	func loadIsCurrencyAmountVisible() -> Bool {
		// TODO: implement
		true
	}
}

// MARK: - Private Methods
private extension AppSettingsWorker {
	// TODO: add fetching from user defaults
}
