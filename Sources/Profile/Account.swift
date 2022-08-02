import Foundation

public struct Account: Equatable {
	var userGeneratedName: String
	var systemGeneratedName: String
	var accountFiatTotalValue: Float
	var accountCurrency: Currency
}
