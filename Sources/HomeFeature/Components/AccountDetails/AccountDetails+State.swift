import AccountWorthFetcher
import Common
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
		public let name: String
		public let tokens: [Token]

		public init(for account: Home.AccountRow.State) {
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name
			tokens = account.tokens
		}
	}
}
