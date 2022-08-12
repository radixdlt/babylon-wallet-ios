import Foundation

// MARK: - Account
public struct Account: Equatable {
	public var userGeneratedName: String
	public var systemGeneratedName: String
	public var accountFiatTotalValue: Float
	public var accountCurrency: Currency

	public init(
		userGeneratedName: String,
		systemGeneratedName: String,
		accountFiatTotalValue: Float,
		accountCurrency: Currency
	) {
		self.userGeneratedName = userGeneratedName
		self.systemGeneratedName = systemGeneratedName
		self.accountFiatTotalValue = accountFiatTotalValue
		self.accountCurrency = accountCurrency
	}
}

public extension Account {
	var fiatTotalValueString: String {
		accountFiatTotalValue
			.formatted(
				.currency(code: accountCurrency.code)
			)
	}
}

public extension Account {
	static var `default`: Account = .init(
		userGeneratedName: "Name",
		systemGeneratedName: "System name",
		accountFiatTotalValue: 10_000_000_000,
		accountCurrency: .usd
	)
}
