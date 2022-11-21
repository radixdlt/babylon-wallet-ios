import Foundation
import Profile

// MARK: - NonFungibleToken
public struct NonFungibleToken: Sendable, Asset, Token, Hashable {
	public let address: ComponentAddress

	public let nonFungibleID: String

	public let isDeleted: Bool

	// FIXME: this needs to be translated into something well structured.
	public let nonFungibleDataAsString: String
	public var iconURL: URL?

	public init(
		address: ComponentAddress,
		nonFungibleID: String,
		isDeleted: Bool,
		nonFungibleDataAsString: String,
		iconURL: URL? = nil
	) {
		self.address = address
		self.nonFungibleID = nonFungibleID
		self.isDeleted = isDeleted
		self.nonFungibleDataAsString = nonFungibleDataAsString
		self.iconURL = iconURL
	}
}

// MARK: - NonFungibleTokenContainer
public struct NonFungibleTokenContainer: AssetContainer {
	public var owner: AccountAddress
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
		address: "nft1-deadbeef",
		nonFungibleID: "nft1-deadbeef-nft1-deadbeef",
		isDeleted: false,
		nonFungibleDataAsString: "<metadata goes here>"
	)

	static let mock2 = Self(
		address: "nft2-deadbeef",
		nonFungibleID: "nft2-deadbeef-nft2-deadbeef",
		isDeleted: false,
		nonFungibleDataAsString: "<metadata goes here>"
	)

	static let mock3 = Self(
		address: "nft3-deadbeef",
		nonFungibleID: "nft1-deadbeef-nft1-deadbeef",
		isDeleted: true,
		nonFungibleDataAsString: "<metadata goes here>"
	)
}
#endif
