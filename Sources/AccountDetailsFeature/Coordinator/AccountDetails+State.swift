import AccountListFeature
import AccountWorthFetcher
import Address
import AggregatedValueFeature
import AssetListFeature
import ComposableArchitecture
import Foundation
import Profile

// MARK: - AccountDetails
/// Namespace for AccountDetailsFeature
public enum AccountDetails {}

public extension AccountDetails {
	// MARK: State
	struct State: Equatable {
		// dzoni
		public let account: Profile.Account
		public let address: Address
		public var aggregatedValue: AggregatedValue.State
		public let name: String
		public var assetList: AssetList.State

		public init(for account: AccountList.Row.State) {
			self.account = account.account
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name

			assetList = .init(
				sections: .init(uniqueElements: AssetListSorter.live.sortTokens(account.tokenContainers).map { category in
					let rows = category.tokenContainers.map { container in AssetList.Row.State(tokenContainer: container, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible) }
					return AssetList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
				})
			)
		}
	}
}
