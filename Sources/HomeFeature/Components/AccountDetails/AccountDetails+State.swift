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
		public var assetList: Home.AssetList.State

		public init(for account: Home.AccountRow.State) {
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name

			assetList = .init(
				sections: .init(uniqueElements: account.sectionedTokenContainers.map { containers in
					let rows = containers.map { container in Home.AssetRow.State(tokenContainer: container, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible) }
					return Home.AssetSection.State(assets: .init(uniqueElements: rows))
				})
			)
		}
	}
}
