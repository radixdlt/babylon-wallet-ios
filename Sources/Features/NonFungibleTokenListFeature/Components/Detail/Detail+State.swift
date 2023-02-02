import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail.State
public extension NonFungibleTokenList.Detail {
	struct State: Sendable, Hashable {
		var container: NonFungibleTokenContainer
		var asset: NonFungibleToken
	}
}

#if DEBUG
public extension NonFungibleTokenList.Detail.State {
	static let previewValue = Self(
		container: NonFungibleTokenContainer(
			owner: try! .init(address: "owner_address"),
			resourceAddress: .init(address: "resource_address"),
			assets: [.mock1, .mock2, .mock3],
			name: "NFT Collection",
			description: "A collection of NFTs",
			iconURL: nil
		),
		asset: .mock1
	)
}
#endif
