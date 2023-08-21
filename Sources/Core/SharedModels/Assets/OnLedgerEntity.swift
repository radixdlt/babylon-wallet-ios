import EngineKit
import Foundation
import Prelude

// MARK: - FungibleResource
public struct FungibleResource: Sendable, Hashable, Codable {
	public let resourceAddress: ResourceAddress
	public let divisibility: Int?
	public let name: String?
	public let symbol: String?
	public let description: String?
	public let iconURL: URL?
	public let behaviors: [AssetBehavior]
	public let tags: [AssetTag]
	public let totalSupply: BigDecimal?

	public init(
		resourceAddress: ResourceAddress,
		divisibility: Int?,
		name: String?,
		symbol: String?,
		description: String?,
		iconURL: URL?,
		behaviors: [AssetBehavior],
		tags: [AssetTag],
		totalSupply: BigDecimal?
	) {
		self.resourceAddress = resourceAddress
		self.divisibility = divisibility
		self.name = name
		self.symbol = symbol
		self.description = description
		self.iconURL = iconURL
		self.behaviors = behaviors
		self.tags = tags
		self.totalSupply = totalSupply
	}
}

// MARK: - NonFungibleResource
public struct NonFungibleResource: Sendable, Hashable, Codable {
	public let resourceAddress: ResourceAddress
	public let name: String?
	public let description: String?
	public let iconURL: URL?
	public let behaviors: [AssetBehavior]
	public let tags: [AssetTag]
	public let totalSupply: BigDecimal?

	public init(
		resourceAddress: ResourceAddress,
		name: String?,
		description: String?,
		iconURL: URL?,
		behaviors: [AssetBehavior],
		tags: [AssetTag],
		totalSupply: BigDecimal?
	) {
		self.resourceAddress = resourceAddress
		self.name = name
		self.description = description
		self.iconURL = iconURL
		self.behaviors = behaviors
		self.tags = tags
		self.totalSupply = totalSupply
	}
}
