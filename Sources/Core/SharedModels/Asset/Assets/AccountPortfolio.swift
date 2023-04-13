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
	//        public struct FungibleResources: Sendable, Hashable {
	//                public init(
	//                        xrdToken: FungibleToken?,
	//                        tokens: PaginatedResourceContainer<[AccountPortfolio.FungibleToken]>
	//                ) {
	//                        self.xrdToken = xrdToken
	//                        self.tokens = tokens
	//                }
//
	//                public let xrdToken: FungibleToken?
	//                public let tokens: PaginatedResourceContainer<[FungibleToken]>
	//        }

	public typealias FungibleResources = PaginatedResourceContainer<[FungibleToken]>
	public typealias NonFungibleResources = PaginatedResourceContainer<[NonFungibleToken]>

	public struct FungibleToken: Sendable, Hashable, Codable {
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

	public struct NonFungibleToken: Sendable, Hashable, Codable {
		public let resourceAddress: ResourceAddress
		public let name: String?
		public let description: String?
		// The number of tokens owned by the Account
		public let amount: Int

		// TODO: Should not be just string
		public let ids: PaginatedResourceContainer<[String]>

		public init(
			resourceAddress: ResourceAddress,
			name: String? = nil,
			description: String? = nil,
			amount: Int,
			ids: PaginatedResourceContainer<[String]>
		) {
			self.resourceAddress = resourceAddress
			self.name = name
			self.description = description
			self.amount = amount
			self.ids = ids
		}
	}
}
