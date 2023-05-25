import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail
extension NonFungibleAssetList {
	// MARK: - NonFungibleTokenDetails
	public struct Detail: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			let token: AccountPortfolio.NonFungibleResource.NonFungibleToken
			let resource: AccountPortfolio.NonFungibleResource
		}

		public init() {}
	}
}
