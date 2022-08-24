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
		public let aggregatedValue: Float?
		public let currency: FiatCurrency
		public let name: String?
		public let tokens: [Home.AccountRow.Token]

		public init(for account: Home.AccountRow.State) {
			address = account.address
			aggregatedValue = account.aggregatedValue
			currency = account.currency
			name = account.name
			tokens = account.tokens
		}
	}
}
