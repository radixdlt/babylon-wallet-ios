import AccountWorthFetcher
import ComposableArchitecture
import Foundation
import Profile

// MARK: - AccountDetails
/// Namespace for AccountDetailsFeature
public extension Home {
	enum AccountDetails {}
}

public extension Home.AccountDetails {
	// MARK: State
	struct State: Equatable {
		public let account: Profile.Account
		public let address: Profile.Account.Address
		public var aggregatedValue: Home.AggregatedValue.State
		public let name: String
		public var assetList: Home.AssetList.State

		public init(for account: Home.AccountRow.State) {
			self.account = account.account
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name

			assetList = .init(
				sections: .init(uniqueElements: AssetListSorter.live.sortTokens(account.tokenContainers).map { containers in
					let rows = containers.map { container in Home.AssetRow.State(tokenContainer: container, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible) }
					return Home.AssetSection.State(assets: .init(uniqueElements: rows))
				})
			)
		}
	}
}
