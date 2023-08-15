import FeaturePrelude

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let token: AccountPortfolio.NonFungibleResource.NonFungibleToken
		let resource: AccountPortfolio.NonFungibleResource
	}

	public init() {}
}
