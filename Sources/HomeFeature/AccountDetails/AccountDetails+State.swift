import Foundation

// MARK: - AccountDetails
/// Namespace for AccountDetailsFeature
public enum AccountDetails {}

public extension AccountDetails {
	// MARK: State
	struct State: Equatable {
		public let address: String
		public let aggregatedValue: Float?
		public let currency: FiatCurrency
		public let name: String?
		public let tokens: [Home.AccountRow.Token]

		public init(state: Home.AccountRow.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
			currency = state.currency
			name = state.name
			tokens = state.tokens
		}
	}
}
