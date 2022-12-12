import EngineToolkit
import Foundation
import Profile

// MARK: - NonFungibleToken
public struct NonFungibleToken: Sendable, Asset, Token, Hashable {
	public let address: ComponentAddress

	public let iconURL: URL?

	public init(
		address: ComponentAddress,
		iconURL: URL? = nil
	) {
		self.address = address
		self.iconURL = iconURL
	}
}

// MARK: - NonFungibleTokenContainer
public struct NonFungibleTokenContainer: AssetContainer {
	public let owner: AccountAddress
	public typealias T = NonFungibleToken
	public var asset: NonFungibleToken

	/// Metadata unique to this asset.
	public var metadata: [[String: String]]?

	public init(
		owner: AccountAddress,
		asset: NonFungibleToken,
		metadata: [[String: String]]?
	) {
		self.owner = owner
		self.asset = asset
		self.metadata = metadata
	}
}

#if DEBUG
public extension NonFungibleToken {
	static let mock1 = Self(
		address: "nft1-deadbeef"
	)

	static let mock2 = Self(
		address: "nft2-deadbeef"
	)

	static let mock3 = Self(
		address: "nft3-deadbeef"
	)
}
#endif
