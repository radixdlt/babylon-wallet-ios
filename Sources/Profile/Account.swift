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

#if DEBUG
public extension Account {
	static let placeholder: Account = .init(
		userGeneratedName: "Name",
		systemGeneratedName: "System name",
		fiatTotalValue: 10_000_000_000,
		currency: .usd
	)

	static let checking: Account = .init(
		userGeneratedName: "Checking",
		systemGeneratedName: "checking acount",
		fiatTotalValue: 10000,
		currency: .usd
	)

	static let savings: Account = .init(
		userGeneratedName: "Savings",
		systemGeneratedName: "savings acount",
		fiatTotalValue: 10000,
		currency: .usd
	)

	static let deposit: Account = .init(
		userGeneratedName: "Deposit",
		systemGeneratedName: "deposit acount",
		fiatTotalValue: 10000,
		currency: .usd
	)
}
#endif
