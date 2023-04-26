import Prelude

// MARK: - AccountPortfolio
/// Describes all of the owned resources by a given account
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
	public typealias NonFungibleResources = [NonFungibleResource]

	public struct FungibleResources: Sendable, Hashable, Codable {
		public let xrdResource: FungibleResource?
		public let nonXrdResources: [FungibleResource]

		public init(
			xrdResource: AccountPortfolio.FungibleResource? = nil,
			nonXrdResources: [AccountPortfolio.FungibleResource] = []
		) {
			self.xrdResource = xrdResource
			self.nonXrdResources = nonXrdResources
		}
	}

	public struct FungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress { resourceAddress }

		public let resourceAddress: ResourceAddress
		public let amount: BigDecimal
		public let divisibility: Int?
		public let name: String?
		public let symbol: String?
		public let description: String?
		public let iconURL: URL?
		// TBD: Add the rest of required metadata fields

		public init(
			resourceAddress: ResourceAddress,
			amount: BigDecimal,
			divisibility: Int? = nil,
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil
		) {
			self.resourceAddress = resourceAddress
			self.amount = amount
			self.divisibility = divisibility
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let name: String?
		public let description: String?
		public let iconURL: URL?
		public let tokens: [NonFungibleToken]

		public init(
			resourceAddress: ResourceAddress,
			name: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			tokens: [NonFungibleToken] = []
		) {
			self.resourceAddress = resourceAddress
			self.name = name
			self.description = description
			self.iconURL = iconURL
			self.tokens = tokens
		}

		public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
			public typealias ID = Tagged<Self, String>

			public let id: ID
			public let name: String?
			public let description: String?
			public let keyImageURL: URL?

			public init(id: ID, name: String?, description: String?, keyImageURL: URL?) {
				self.id = id
				self.name = name
				self.description = description
				self.keyImageURL = keyImageURL
			}
		}
	}
}
