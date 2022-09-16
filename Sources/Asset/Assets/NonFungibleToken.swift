import Foundation

// MARK: - NonFungibleToken
public struct NonFungibleToken: Asset, Token {
	public let address: ComponentAddress
	public let supply: Supply

	/// Token icon URL.
	public var iconURL: String?

	public init(
		address: ComponentAddress,
		supply: Supply,
		iconURL: String?
	) {
		self.address = address
		self.supply = supply
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
	static let mock = Self(
		address: "mock",
		supply: .fixed(100),
		iconURL: nil
	)
}
#endif
