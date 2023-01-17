import ClientPrelude

// MARK: - AppSettings
public struct AppSettings: Sendable, Codable, Hashable {
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
	static let `default`: Self = .init(
		currency: .usd,
		isCurrencyAmountVisible: true
	)
}
