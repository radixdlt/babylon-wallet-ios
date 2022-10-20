import Foundation

// MARK: - NonFungibleToken
public struct NonFungibleToken: Asset, Token {
	public let address: ComponentAddress
	// TODO: add supply when API is ready

	/// Token icon URL.
	public var iconURL: String?

	public init(
		address: ComponentAddress,
		iconURL: String?
	) {
		self.address = address
		self.iconURL = iconURL
	}
}

// MARK: - NonFungibleTokenContainer
public struct NonFungibleTokenContainer: AssetContainer {
	public typealias T = NonFungibleToken
	public let asset: NonFungibleToken

	/// Metadata unique to this asset.
	public var metadata: [[String: String]]?

	public init(
		asset: NonFungibleToken,
		metadata: [[String: String]]?
	) {
		self.asset = asset
		self.metadata = metadata
	}
}

#if DEBUG
public extension NonFungibleToken {
	static let mock1 = Self(
		address: "nft1-deadbeef",
		iconURL: nil
	)

	static let mock2 = Self(
		address: "nft2-deadbeef",
		iconURL: nil
	)

	static let mock3 = Self(
		address: "nft3-deadbeef",
		iconURL: nil
	)
}
#endif
