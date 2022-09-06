import Common
import Foundation

// MARK: - AppSettings
public struct AppSettings: Codable {
	public var currency: FiatCurrency
	public var isCurrencyAmountVisible: Bool

	public init(
		currency: FiatCurrency,
		isCurrencyAmountVisible: Bool
	) {
		self.currency = currency
		self.isCurrencyAmountVisible = isCurrencyAmountVisible
	}
}

public extension AppSettings {
	static let defaults: AppSettings = .init(
		currency: .usd,
		isCurrencyAmountVisible: false
	)
}
