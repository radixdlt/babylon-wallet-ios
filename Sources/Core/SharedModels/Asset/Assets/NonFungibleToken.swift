import EngineToolkitModels
import Prelude
import ProfileModels

// MARK: - NonFungibleToken
public struct NonFungibleToken: Sendable, Token, Hashable {
	public let nonFungibleLocalId: ID
	public typealias ID = NonFungibleLocalId
	public var id: ID { nonFungibleLocalId }

	public init(
		nonFungibleLocalId: ID
	) {
		self.nonFungibleLocalId = nonFungibleLocalId
	}
}

// MARK: - NonFungibleTokenContainer
public struct NonFungibleTokenContainer: Sendable, Identifiable, Hashable {
	public let owner: AccountAddress
	public let resourceAddress: ComponentAddress
	public var assets: [NonFungibleToken]

	public typealias ID = ComponentAddress
	public var id: ID { resourceAddress }

	public let name: String?
	public let description: String?
	public let iconURL: URL?

	public init(
		owner: AccountAddress,
		resourceAddress: ComponentAddress,
		assets: [NonFungibleToken],
		name: String?,
		description: String?,
		iconURL: URL?
	) {
		self.owner = owner
		self.resourceAddress = resourceAddress
		self.assets = assets
		self.name = name
		self.description = description
		self.iconURL = iconURL
	}
}

#if DEBUG
extension NonFungibleTokenContainer {
	public static let mock1 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-1"),
		assets: [.mock1, .mock2, .mock3],
		name: "Mock Resource 1",
		description: "A description for Mock Resource 1",
		iconURL: nil
	)

	public static let mock2 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-2"),
		assets: [.mock1, .mock2, .mock3],
		name: "Name",
		description: nil,
		iconURL: nil
	)

	public static let mock3 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-3"),
		assets: [.mock1, .mock2, .mock3],
		name: "Name",
		description: nil,
		iconURL: nil
	)
}

extension NonFungibleToken {
	public static let mock1 = Self(
		nonFungibleLocalId: .string("nft1-deadbeef")
	)

	public static let mock2 = Self(
		nonFungibleLocalId: .string("nft2-deadbeef")
	)

	public static let mock3 = Self(
		nonFungibleLocalId: .string("nft3-deadbeef")
	)
}
#endif
