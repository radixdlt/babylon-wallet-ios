import Prelude

// MARK: - AccountPortfolio
/// Describes all of the owned resources by a given account
public struct AccountPortfolio: Sendable, Hashable, Codable {
	public let owner: AccountAddress
	public let isDappDefintionAccountType: Bool
	public var fungibleResources: FungibleResources
	public var nonFungibleResources: NonFungibleResources

	public init(
		owner: AccountAddress,
		isDappDefintionAccountType: Bool,
		fungibleResources: FungibleResources,
		nonFungibleResources: NonFungibleResources
	) {
		self.owner = owner
		self.isDappDefintionAccountType = isDappDefintionAccountType
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
		public typealias GlobalID = String
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let name: String?
		public let description: String?
		public let iconURL: URL?
		public let tokens: IdentifiedArrayOf<NonFungibleToken>

		public init(
			resourceAddress: ResourceAddress,
			name: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			tokens: IdentifiedArrayOf<NonFungibleToken> = []
		) {
			self.resourceAddress = resourceAddress
			self.name = name
			self.description = description
			self.iconURL = iconURL
			self.tokens = tokens
		}

		public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
			public typealias LocalID = Tagged<Self, String>

			public let id: LocalID
			public let name: String?
			public let description: String?
			public let keyImageURL: URL?
			public let metadata: [Metadata]

			public init(id: ID, name: String?, description: String?, keyImageURL: URL?, metadata: [Metadata]) {
				self.id = id
				self.name = name
				self.description = description
				self.keyImageURL = keyImageURL
				self.metadata = metadata
			}
		}
	}

	public struct Metadata: Sendable, Hashable, Identifiable, Codable {
		public var id: String { key }
		public let key: String
		public let value: String

		public init(key: String, value: String) {
			self.key = key
			self.value = value
		}
	}
}

extension AccountPortfolio.NonFungibleResource {
	public func nftGlobalID(for id: NonFungibleToken.LocalID) throws -> GlobalID {
		try resourceAddress.nftGlobalId(id).formatted
	}
}

extension NonFungibleGlobalId {
	public var formatted: String {
		asStr()
		// resourceAddress.address + ":" + nonFungibleLocalId.value
	}
}

extension ResourceAddress {
	public func nftGlobalId(_ localID: AccountPortfolio.NonFungibleResource.NonFungibleToken.LocalID) throws -> NonFungibleGlobalId {
		try .fromParts(resourceAddress: self.toEngine(), nonFungibleLocalId: .str(value: localID.rawValue))
		// .init(resourceAddress: self, nonFungibleLocalId: .init(value: localID.rawValue))
	}
}

extension String {
	/// Creates a user facing string for a  local non fungible ID
	public var userFacingNonFungibleLocalID: String {
		// Just a safety guard. Each NFT Id should be of format <prefix>value<suffix>
		guard count >= 3 else {
			loggerGlobal.warning("Invalid nft id: \(self)")
			return self
		}
		// Nothing fancy, just remove the prefix and suffix.
		return String(dropLast().dropFirst())
	}
}

extension AccountPortfolio {
	/// Returns an instance with all empty vaults filtered out
	public var nonEmptyVaults: Self {
		.init(
			owner: owner,
			isDappDefintionAccountType: isDappDefintionAccountType,
			fungibleResources: .init(
				xrdResource: fungibleResources.xrdResource?.nonEmpty,
				nonXrdResources: fungibleResources.nonXrdResources.compactMap(\.nonEmpty)
			),
			nonFungibleResources: nonFungibleResources.compactMap(\.nonEmpty)
		)
	}
}

extension AccountPortfolio.FungibleResource {
	/// Returns nil
	public var nonEmpty: Self? {
		amount == 0 ? nil : self
	}
}

extension AccountPortfolio.NonFungibleResource {
	public var nonEmpty: Self? {
		tokens.isEmpty ? nil : self
	}
}
