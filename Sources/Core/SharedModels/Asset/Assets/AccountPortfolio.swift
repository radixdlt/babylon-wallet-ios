import Prelude

// MARK: - PaginatedResource
public struct PaginatedResource<Resource: Hashable & Sendable>: Hashable, Sendable {
	public let totalCount: Int
	// Optional when not loaded
	public let items: [Resource]?

	public init(totalCount: Int, items: [Resource]? = nil) {
		self.totalCount = totalCount
		self.items = items
	}
}

// MARK: - AccountPortfolio
public struct AccountPortfolio: Sendable, Hashable, Codable {
	public let owner: AccountAddress
	public var fungibleResources: FungibleResources
	public var nonFungibleResources: NonFungibleResources

	public init(
		owner: AccountAddress,
		fungibleResources: FungibleResources,
		nonFungibleResources: NonFungibleResources
	) {
		self.owner = owner
		self.fungibleResources = fungibleResources
		self.nonFungibleResources = nonFungibleResources
	}
}

extension AccountPortfolio {
	public typealias FungibleResources = [FungibleResource]
	public typealias NonFungibleResources = [NonFungibleResource]

	public struct FungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress { self.resourceAddress }
		public let resourceAddress: ResourceAddress
		public let amount: BigDecimal
		public let divisibility: Int?
		public let name: String?
		public let symbol: String?
		public let description: String?

		public init(
			resourceAddress: ResourceAddress,
			amount: BigDecimal,
			divisibility: Int? = nil,
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil
		) {
			self.resourceAddress = resourceAddress
			self.amount = amount
			self.divisibility = divisibility
			self.name = name
			self.symbol = symbol
			self.description = description
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress { self.resourceAddress }
		public let resourceAddress: ResourceAddress
		public let name: String?
		public let description: String?
		public let ids: [String]

		public init(
			resourceAddress: ResourceAddress,
			name: String? = nil,
			description: String? = nil,
			ids: [String]
		) {
			self.resourceAddress = resourceAddress
			self.name = name
			self.description = description
			self.ids = ids
		}
	}
}
