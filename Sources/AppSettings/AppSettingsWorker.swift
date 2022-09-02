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
	func saveCurrency(_ currency: FiatCurrency) async {
		do {
			let currencyData = try JSONEncoder().encode(currency)
			await userDefaultsClient.setData(currencyData, Key.currency.rawValue)
		} catch {
			print(error.localizedDescription)
		}
	}

	func loadCurrency() -> FiatCurrency {
		guard let data = userDefaultsClient.dataForKey(Key.currency.rawValue),
		      let currency = try? JSONDecoder().decode(FiatCurrency.self, from: data)
		else {
			print("Error loading currency")
			return .usd
		}
		return currency
	}

	func saveIsCurrencyAmountVisible(_ value: Bool) async {
		await userDefaultsClient.setBool(value, Key.isCurrencyAmountVisible.rawValue)
	}

	func loadIsCurrencyAmountVisible() -> Bool {
		userDefaultsClient.boolForKey(Key.isCurrencyAmountVisible.rawValue)
	}
}

// MARK: - Private Methods
private extension AppSettingsWorker {
	enum Key: String {
		case currency
		case isCurrencyAmountVisible
	}
}
