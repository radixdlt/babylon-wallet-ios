import AccountListFeature
import Address
import AggregatedValueFeature
import Asset
import AssetsViewFeature
import ComposableArchitecture
import Foundation
import FungibleTokenListFeature
import Profile

// MARK: - AccountDetails
/// Namespace for AccountDetailsFeature
public enum AccountDetails {}

// MARK: AccountDetails.State
public extension AccountDetails {
	// MARK: State
	struct State: Equatable {
		public let account: Profile.Account
		public let address: Address
		public var aggregatedValue: AggregatedValue.State
		public let name: String
		public var assets: AssetsView.State

		public init(for account: AccountList.Row.State) {
			self.account = account.account
			address = account.address
			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)
			name = account.name

			let fungibleTokenCategories = FungibleTokenListSorter.live.sortTokens(account.portfolio.fungibleTokenContainers)
			assets = .init(
				fungibleTokenList: .init(
					sections: .init(uniqueElements: fungibleTokenCategories.map { category in
						let rows = category.tokenContainers.map { container in FungibleTokenList.Row.State(container: container, currency: account.currency, isCurrencyAmountVisible: account.isCurrencyAmountVisible) }
						return FungibleTokenList.Section.State(id: category.type, assets: .init(uniqueElements: rows))
					})
				)
			)
		}
	}
}
