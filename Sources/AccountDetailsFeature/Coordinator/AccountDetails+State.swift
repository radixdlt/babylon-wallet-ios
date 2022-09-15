import AccountListFeature
import AccountWorthFetcher
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
		public let account: Profile.Account
		public let address: Profile.Account.Address
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
				sections: .init(uniqueElements: AssetListSorter.live.sortTokens(account.tokenContainers).map { containers in
					let rows = containers.map { container in AssetList.Row.State(tokenContainer: container, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible) }
					return AssetList.Section.State(assets: .init(uniqueElements: rows))
				})
			)
		}
	}
}
