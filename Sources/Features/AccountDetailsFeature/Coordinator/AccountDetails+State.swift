import AccountListFeature
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
		public let account: OnNetwork.Account
		public var aggregatedValue: AggregatedValue.State
		public var assets: AssetsView.State

		public init(for account: AccountList.Row.State) {
			self.account = account.account

			aggregatedValue = .init(
				value: account.aggregatedValue,
				currency: account.currency,
				isCurrencyAmountVisible: account.isCurrencyAmountVisible
			)

			let fungibleTokenCategories = account.portfolio.fungibleTokenContainers.sortedIntoCategories()

			assets = .init(
				fungibleTokenList: .init(
					sections: .init(uniqueElements: fungibleTokenCategories.map { category in
						let rows = category.tokenContainers.map { container in
							FungibleTokenList.Row.State(
								container: container,
								currency: account.currency,
								isCurrencyAmountVisible: account.isCurrencyAmountVisible
							)
						}
						return FungibleTokenList.Section.State(
							id: category.type,
							assets: .init(uniqueElements: rows)
						)
					})
				),

				nonFungibleTokenList: .init(
					rows: .init(uniqueElements: [account.portfolio.nonFungibleTokenContainers].map {
						.init(containers: $0)
					})
				)
			)
		}
	}
}

public extension AccountDetails.State {
	var address: AccountAddress {
		account.address
	}

	var displayName: String {
		account.displayName ?? "Unnamed account"
	}
}
