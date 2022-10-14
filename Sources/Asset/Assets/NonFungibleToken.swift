import Foundation
import GatewayAPI

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

// MARK: - Convenience
public extension NonFungibleToken {
	init(
		address: ComponentAddress,
		details _: EntityDetailsResponseNonFungibleDetails
	) {
		self.init(
			address: address,
			// TODO: update when API is ready
			iconURL: nil
		)
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
		iconURL: nil
	)
}
#endif
