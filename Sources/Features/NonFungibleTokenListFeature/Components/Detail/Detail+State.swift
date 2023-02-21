import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail.State
extension NonFungibleTokenList.Detail {
	public struct State: Sendable, Hashable {
		var container: NonFungibleTokenContainer
		var asset: NonFungibleToken
	}
}

#if DEBUG
extension NonFungibleTokenList.Detail.State {
	public static let previewValue = Self(
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
