import EngineToolkit
import Foundation
import Profile

// MARK: - NonFungibleToken
public struct NonFungibleToken: Sendable, Token, Hashable {
	public let nonFungibleId: ID
	public typealias ID = NonFungibleId
	public var id: ID { nonFungibleId }

	public init(
		nonFungibleId: ID
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
public extension NonFungibleTokenContainer {
	static let mock1 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-1"),
		assets: [.mock1, .mock2, .mock3],
		name: "Mock Resource 1",
		description: "A description for Mock Resource 1",
		iconURL: nil
	)

	static let mock2 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-2"),
		assets: [.mock1, .mock2, .mock3],
		name: "Name",
		description: nil,
		iconURL: nil
	)

	static let mock3 = Self(
		owner: try! .init(address: "account-address"),
		resourceAddress: .init(address: "resource-address-3"),
		assets: [.mock1, .mock2, .mock3],
		name: "Name",
		description: nil,
		iconURL: nil
	)
}

public extension NonFungibleToken {
	static let mock1 = Self(
		nonFungibleId: .string("nft1-deadbeef")
	)

	static let mock2 = Self(
		nonFungibleId: .string("nft2-deadbeef")
	)

	static let mock3 = Self(
		nonFungibleId: .string("nft3-deadbeef")
	)
}
#endif
