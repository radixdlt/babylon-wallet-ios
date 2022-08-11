import Foundation

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
