import Prelude

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

	public struct FungibleResource: Sendable, Hashable, Codable, Identifiable {
                public var id: ResourceAddress { self.resourceAddress }
		public let resourceAddress: ResourceAddress
		public let amount: BigDecimal
		public let divisibility: Int?
		public let name: String?
		public let symbol: String?
		public let tokenDescription: String?

		public init(
			resourceAddress: ResourceAddress,
			amount: BigDecimal,
			divisibility: Int? = nil,
			name: String? = nil,
			symbol: String? = nil,
			tokenDescription: String? = nil
		) {
			self.resourceAddress = resourceAddress
			self.amount = amount
			self.divisibility = divisibility
			self.name = name
			self.symbol = symbol
			self.tokenDescription = tokenDescription
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Codable, Identifiable {
                public var id: ResourceAddress { self.resourceAddress }
		public let resourceAddress: ResourceAddress
		public let name: String?
		public let description: String?
		// The number of tokens owned by the Account
		public let amount: Int

		public init(
			resourceAddress: ResourceAddress,
			name: String? = nil,
			description: String? = nil,
			amount: Int
		) {
			self.resourceAddress = resourceAddress
			self.name = name
			self.description = description
			self.amount = amount
		}
	}
}
