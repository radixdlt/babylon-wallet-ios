import Foundation

// MARK: - Account
public struct Account: Equatable {
	public var userGeneratedName: String
	public var systemGeneratedName: String
	public var fiatTotalValue: Float
	public var currency: Currency

	public init(
		userGeneratedName: String,
		systemGeneratedName: String,
		fiatTotalValue: Float,
		currency: Currency
	) {
		self.userGeneratedName = userGeneratedName
		self.systemGeneratedName = systemGeneratedName
		self.fiatTotalValue = fiatTotalValue
		self.currency = currency
	}
}

public extension Account {
	var fiatTotalValueString: String {
		fiatTotalValue
			.formatted(
				.currency(code: currency.code)
			)
	}
}

public extension Account {
	static var `default`: Account = .init(
		userGeneratedName: "Name",
		systemGeneratedName: "System name",
		fiatTotalValue: 10_000_000_000,
		currency: .usd
	)
}
