import AccountListFeature
import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude
import FungibleTokenListFeature

// MARK: - AccountDetails.State
public extension AccountDetails {
	// MARK: State
	struct State: Sendable, Equatable {
		public enum Destination: Sendable, Equatable {
			// TODO: case preferences(AccountPreferences.State)
			case transfer(AssetTransfer.State)
		}

		public let account: OnNetwork.Account
		public var assets: AssetsView.State
		public var destination: Destination?

		public init(for account: AccountList.Row.State, destination: Destination? = nil) {
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

			self.destination = destination
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
