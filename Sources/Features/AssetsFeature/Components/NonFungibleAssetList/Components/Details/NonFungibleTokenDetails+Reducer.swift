import FeaturePrelude

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let token: AccountPortfolio.NonFungibleResource.NonFungibleToken?
		public let resource: AccountPortfolio.NonFungibleResource

		public init(token: AccountPortfolio.NonFungibleResource.NonFungibleToken?, resource: AccountPortfolio.NonFungibleResource) {
			self.token = token
			self.resource = resource
		}
	}

	public init() {}
}
