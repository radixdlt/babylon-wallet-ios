import Foundation

// MARK: - AccountDetails
/// Namespace for AccountDetailsFeature
public extension Home {
	enum AccountDetails {}
}

public extension Home.AccountDetails {
	// MARK: State
	struct State: Equatable {
		public let address: String
		public var aggregatedValue: Home.AggregatedValue.State
		public let currency: FiatCurrency
		public let name: String
		public let tokens: [Home.AccountRow.Token]
		public var isCurrencyAmountVisible: Bool

		public init(for account: Home.AccountRow.State) {
			address = account.address
			aggregatedValue = .init(value: account.aggregatedValue, isVisible: account.isValueVisible)
			currency = account.currency
			name = account.name
			tokens = account.tokens
			isCurrencyAmountVisible = account.isValueVisible
		}
	}
}
