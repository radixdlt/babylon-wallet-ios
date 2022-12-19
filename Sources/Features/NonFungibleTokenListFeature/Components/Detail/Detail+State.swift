import Asset
import EngineToolkit
import Foundation
import SharedModels

// MARK: - NonFungibleTokenList.Detail.State
public extension NonFungibleTokenList.Detail {
	typealias State = NonFungibleTokenContainer
}

#if DEBUG
public extension NonFungibleTokenList.Detail.State {
	static let previewValue = NonFungibleTokenContainer(
		owner: try! .init(address: "owner_address"),
		resourceAddress: .init(address: "resource_address"),
		assets: [.mock1, .mock2, .mock3],
		name: "NFT Collection",
		description: "A collection of NFTs",
		iconURL: nil
	)
}
#endif
