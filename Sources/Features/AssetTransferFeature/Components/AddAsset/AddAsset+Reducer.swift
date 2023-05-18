import FeaturePrelude

public struct AddAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum DelegateAction: Equatable, Sendable {
		case addFungibleResource(AccountPortfolio.FungibleResource, isXRD: Bool)
		case addNonFungibleResource(ResourceAddress, AccountPortfolio.NonFungibleResource.NonFungibleToken)
	}
}
