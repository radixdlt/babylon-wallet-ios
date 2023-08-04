import EngineKit
import Prelude

// MARK: - AccountPortfolio
/// Describes all of the owned resources by a given account
public struct AccountPortfolio: Sendable, Hashable, Codable {
	public let owner: AccountAddress
	public let isDappDefintionAccountType: Bool
	public var fungibleResources: FungibleResources
	public var nonFungibleResources: NonFungibleResources
	public var poolUnitResources: PoolUnitResources

	public init(
		owner: AccountAddress,
		isDappDefintionAccountType: Bool,
		fungibleResources: FungibleResources,
		nonFungibleResources: NonFungibleResources,
		poolUnitResources: PoolUnitResources
	) {
		self.owner = owner
		self.isDappDefintionAccountType = isDappDefintionAccountType
		self.fungibleResources = fungibleResources
		self.nonFungibleResources = nonFungibleResources
		self.poolUnitResources = poolUnitResources
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
		public let totalSupply: BigDecimal?
		// TBD: Add the rest of required metadata fields

		public init(
			resourceAddress: ResourceAddress,
			amount: BigDecimal,
			divisibility: Int? = nil,
			name: String? = nil,
			symbol: String? = nil,
			description: String? = nil,
			iconURL: URL? = nil,
			totalSupply: BigDecimal? = nil
		) {
			self.resourceAddress = resourceAddress
			self.amount = amount
			self.divisibility = divisibility
			self.name = name
			self.symbol = symbol
			self.description = description
			self.iconURL = iconURL
			self.totalSupply = totalSupply
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Identifiable, Codable {
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
			public let id: NonFungibleGlobalId
			public let name: String?
			public let description: String?
			public let keyImageURL: URL?
			public let metadata: [Metadata]

			// The claim amount if the it is a stake claim nft
			public let stakeClaimAmount: BigDecimal?
			// Epoch when the nft can be claimed
			public let claimEpoch: Epoch?

			// This is temporarily computed directly when loadingt he resource.
			// It should be probably optimized to check the resource can be claimed retroactively by checkingt he network Epoch
			public let canBeClaimed: Bool

			public init(
				id: NonFungibleGlobalId,
				name: String?,
				description: String?,
				keyImageURL: URL?,
				metadata: [Metadata],
				stakeClaimAmount: BigDecimal? = nil,
				claimEpoch: Epoch? = nil,
				canBeClaimed: Bool = false
			) {
				self.id = id
				self.name = name
				self.description = description
				self.keyImageURL = keyImageURL
				self.metadata = metadata
				self.stakeClaimAmount = stakeClaimAmount
				self.claimEpoch = claimEpoch
				self.canBeClaimed = canBeClaimed
			}
		}
	}

	public struct PoolUnitResources: Sendable, Hashable, Codable {
		public let radixNetworkStakes: [RadixNetworkStake]
		public let poolUnits: [String]

		public init(radixNetworkStakes: [RadixNetworkStake], poolUnits: [String]) {
			self.radixNetworkStakes = radixNetworkStakes
			self.poolUnits = poolUnits
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

// MARK: - AccountPortfolio.PoolUnitResources.RadixNetworkStake
extension AccountPortfolio.PoolUnitResources {
	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public struct Validator: Sendable, Hashable, Codable {
			public let address: ValidatorAddress
			public let xrdVaultBalance: BigDecimal
			public let name: String?
			public let description: String?
			public let iconURL: URL?

			public init(
				address: ValidatorAddress,
				xrdVaultBalance: BigDecimal,
				name: String? = nil,
				description: String? = nil,
				iconURL: URL? = nil
			) {
				self.address = address
				self.xrdVaultBalance = xrdVaultBalance
				self.name = name
				self.description = description
				self.iconURL = iconURL
			}
		}

		public let validator: Validator
		public let stakeUnitResource: AccountPortfolio.FungibleResource
		public let stakeClaimResource: AccountPortfolio.NonFungibleResource?

		public var xrdRedemptionValue: BigDecimal {
			(stakeUnitResource.amount * validator.xrdVaultBalance) / (stakeUnitResource.totalSupply ?? .one)
		}

		public init(validator: Validator, stakeUnitResource: AccountPortfolio.FungibleResource, stakeClaimResource: AccountPortfolio.NonFungibleResource?) {
			self.validator = validator
			self.stakeUnitResource = stakeUnitResource
			self.stakeClaimResource = stakeClaimResource
		}
	}
}

extension AccountPortfolio.NonFungibleResource {
	public func nftGlobalID(for id: NonFungibleLocalId) throws -> NonFungibleGlobalId {
		try resourceAddress.nftGlobalId(id)
	}
}

extension ResourceAddress {
	public func nftGlobalId(_ localID: NonFungibleLocalId) throws -> NonFungibleGlobalId {
		try NonFungibleGlobalId.fromParts(resourceAddress: self.intoEngine(), nonFungibleLocalId: localID)
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
			nonFungibleResources: nonFungibleResources.compactMap(\.nonEmpty),
			poolUnitResources: poolUnitResources
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

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	enum CodingKeys: CodingKey {
		case id
		case name
		case description
		case keyImageURL
		case metadata
		case stakeClaimAmount
		case claimEpoch
		case canBeClaimed
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			id: .init(nonFungibleGlobalId: container.decode(String.self, forKey: .id)),
			name: container.decodeIfPresent(String.self, forKey: .name),
			description: container.decodeIfPresent(String.self, forKey: .description),
			keyImageURL: container.decodeIfPresent(URL.self, forKey: .keyImageURL),
			metadata: container.decode([AccountPortfolio.Metadata].self, forKey: .metadata),
			stakeClaimAmount: container.decodeIfPresent(BigDecimal.self, forKey: .stakeClaimAmount),
			claimEpoch: container.decodeIfPresent(Epoch.self, forKey: .claimEpoch),
			canBeClaimed: container.decode(Bool.self, forKey: .canBeClaimed)
		)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id.asStr(), forKey: .id)
		try container.encodeIfPresent(name, forKey: .name)
		try container.encodeIfPresent(description, forKey: .description)
		try container.encodeIfPresent(keyImageURL, forKey: .keyImageURL)
		try container.encode(metadata, forKey: .metadata)
		try container.encodeIfPresent(stakeClaimAmount, forKey: .stakeClaimAmount)
		try container.encodeIfPresent(claimEpoch, forKey: .claimEpoch)
		try container.encode(canBeClaimed, forKey: .canBeClaimed)
	}
}
