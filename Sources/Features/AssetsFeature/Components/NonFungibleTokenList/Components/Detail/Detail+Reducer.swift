import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail
extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	public struct Detail: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			let token: AccountPortfolio.NonFungibleResource.NonFungibleToken
			let resource: AccountPortfolio.NonFungibleResource
		}

		public init() {}
	}
}
