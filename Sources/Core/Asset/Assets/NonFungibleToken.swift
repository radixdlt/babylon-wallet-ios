import EngineToolkit
import Foundation
import Profile

// MARK: - NonFungibleToken
public struct NonFungibleToken: Sendable, Token, Hashable {
	public let nonFungibleId: String
	public typealias ID = String
	public var id: ID { nonFungibleId }

	public init(
		nonFungibleId: String
	) {
		self.nonFungibleId = nonFungibleId
	}
}

// MARK: - NonFungibleTokenContainer
public struct NonFungibleTokenContainer: Identifiable, Equatable {
	public let owner: AccountAddress
	public let resourceAddress: ComponentAddress
	public var assets: [NonFungibleToken]

	public typealias ID = ComponentAddress
	public var id: ID { resourceAddress }

	public let name: String?
	public let symbol: String?
	public let iconURL: URL?

	public init(
		owner: AccountAddress,
		resourceAddress: ComponentAddress,
		assets: [NonFungibleToken],
		name: String?,
		symbol: String?,
		iconURL: URL? = nil
	) {
		self.owner = owner
		self.resourceAddress = resourceAddress
		self.assets = assets
		self.name = name
		self.symbol = symbol
		self.iconURL = iconURL
	}
}

#if DEBUG
public extension NonFungibleToken {
	static let mock1 = Self(
		nonFungibleId: "nft1-deadbeef"
	)

	static let mock2 = Self(
		nonFungibleId: "nft2-deadbeef"
	)

	static let mock3 = Self(
		nonFungibleId: "nft3-deadbeef"
	)
}
#endif
