import AccountWorthFetcher
import ComposableArchitecture
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
		public let assetList: Home.AssetList.State

		public init(for account: Home.AccountRow.State) {
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name

			assetList = .init(
				assets: .init(uniqueElements: account.tokenContainers.map {
					Home.AssetRow.State(id: UUID(), tokenContainer: $0, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible)
				})
			)
		}
	}
}
