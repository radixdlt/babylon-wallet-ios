import AccountListFeature
import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude
import FungibleTokenListFeature

// MARK: - AccountDetails.State
public extension AccountDetails {
	// MARK: State
	struct State: Sendable, Equatable {
		public let account: OnNetwork.Account
		public var assets: AssetsView.State
		@PresentationStateOf<Destinations>
		public var destination

		public init(for account: AccountList.Row.State) {
			self.account = account.account

			let fungibleTokenCategories = account.portfolio.fungibleTokenContainers.elements.sortedIntoCategories()

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
					rows: .init(uniqueElements: account.portfolio.nonFungibleTokenContainers.elements.map {
						.init(container: $0)
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
