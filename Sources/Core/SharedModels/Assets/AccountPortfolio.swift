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
		public let resource: OnLedgerEntity.Resource
		public let amount: RETDecimal

		public var id: ResourceAddress { resourceAddress }
		public var resourceAddress: ResourceAddress { resource.resourceAddress }
		public var divisibility: Int? { resource.divisibility }
		public var name: String? { resource.name }
		public var symbol: String? { resource.symbol }
		public var description: String? { resource.description }
		public var iconURL: URL? { resource.iconURL }
		public var behaviors: [AssetBehavior] { resource.behaviors }
		public var tags: [AssetTag] { resource.tags }
		public var totalSupply: RETDecimal? { resource.totalSupply }

		public init(resource: OnLedgerEntity.Resource, amount: RETDecimal) {
			self.resource = resource
			self.amount = amount
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public let resource: OnLedgerEntity.Resource
		public let tokens: IdentifiedArrayOf<NonFungibleToken>

		public var id: ResourceAddress { resourceAddress }
		public var resourceAddress: ResourceAddress { resource.resourceAddress }
		public var name: String? { resource.name }
		public var symbol: String? { resource.symbol }
		public var description: String? { resource.description }
		public var iconURL: URL? { resource.iconURL }
		public var behaviors: [AssetBehavior] { resource.behaviors }
		public var tags: [AssetTag] { resource.tags }
		public var totalSupply: RETDecimal? { resource.totalSupply }

		public init(resource: OnLedgerEntity.Resource, tokens: IdentifiedArrayOf<NonFungibleToken>) {
			self.resource = resource
			self.tokens = tokens
		}

		public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
			public let id: NonFungibleGlobalId
			public let name: String?
			public let description: String?
			public let keyImageURL: URL?
			public let metadata: [Metadata]

			// The claim amount if the it is a stake claim nft
			public let stakeClaimAmount: RETDecimal?
			// Indication that stake unit amount can be claimed if it is stake claim nft
			public let canBeClaimed: Bool

			public init(
				id: NonFungibleGlobalId,
				name: String?,
				description: String? = nil,
				keyImageURL: URL? = nil,
				metadata: [Metadata] = [],
				stakeClaimAmount: RETDecimal? = nil,
				canBeClaimed: Bool = false
			) {
				self.id = id
				self.name = name
				self.description = description
				self.keyImageURL = keyImageURL
				self.metadata = metadata
				self.stakeClaimAmount = stakeClaimAmount
				self.canBeClaimed = canBeClaimed
			}
		}
	}

	public struct PoolUnitResources: Sendable, Hashable, Codable {
		public let radixNetworkStakes: [RadixNetworkStake]
		public let poolUnits: [PoolUnit]

		public init(radixNetworkStakes: [RadixNetworkStake], poolUnits: [PoolUnit]) {
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
	public struct PoolUnit: Sendable, Hashable, Codable {
		public let poolAddress: ResourcePoolAddress
		public let poolUnitResource: AccountPortfolio.FungibleResource
		public let poolResources: AccountPortfolio.FungibleResources

		public init(
			poolAddress: ResourcePoolAddress,
			poolUnitResource: AccountPortfolio.FungibleResource,
			poolResources: AccountPortfolio.FungibleResources
		) {
			self.poolAddress = poolAddress
			self.poolUnitResource = poolUnitResource
			self.poolResources = poolResources
		}

		public func redemptionValue(for resource: AccountPortfolio.FungibleResource) -> String {
			guard let poolUnitTotalSupply = poolUnitResource.resource.totalSupply else {
				loggerGlobal.error("Missing total supply for \(resource.resourceAddress.address)")
				return "Missing Total supply - could not calculate redemption value" // FIXME: Strings
			}
			let redemptionValue = poolUnitResource.amount * (resource.amount / poolUnitTotalSupply)
			let decimalPlaces = resource.resource.divisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
			let roundedRedemptionValue = redemptionValue.rounded(decimalPlaces: decimalPlaces)

			return roundedRedemptionValue.formatted()
		}
	}

	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public struct Validator: Sendable, Hashable, Codable {
			public let address: ValidatorAddress
			public let xrdVaultBalance: RETDecimal
			public let name: String?
			public let description: String?
			public let iconURL: URL?

			public init(
				address: ValidatorAddress,
				xrdVaultBalance: RETDecimal,
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
		public let stakeUnitResource: AccountPortfolio.FungibleResource?
		public let stakeClaimResource: AccountPortfolio.NonFungibleResource?

		public var xrdRedemptionValue: RETDecimal? {
			guard let stakeUnitResource, let totalSupply = stakeUnitResource.resource.totalSupply else {
				return nil
			}
			return validator.xrdVaultBalance * (stakeUnitResource.amount / totalSupply)
		}

		public init(validator: Validator, stakeUnitResource: AccountPortfolio.FungibleResource?, stakeClaimResource: AccountPortfolio.NonFungibleResource?) {
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

// MARK: - AccountPortfolio.NonFungibleResource.NonFungibleToken.NFTData
extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	public struct NFTData: Sendable, Hashable, Codable {
		public enum Field: String, Sendable, Hashable, Codable {
			case name
			case description
			case keyImageURL = "key_image_url"
			case claimEpoch = "claim_epoch"
			case claimAmount = "claim_amount"
		}

		public enum Value: Sendable, Hashable, Codable {
			case string(String)
			case url(URL)
			case decimal(RETDecimal)
			case u64(UInt64)

			var string: String? {
				guard case let .string(str) = self else {
					return nil
				}
				return str
			}

			var url: URL? {
				guard case let .url(url) = self else {
					return nil
				}
				return url
			}

			var u64: UInt64? {
				guard case let .u64(u64) = self else {
					return nil
				}
				return u64
			}

			var decimal: RETDecimal? {
				guard case let .decimal(decimal) = self else {
					return nil
				}
				return decimal
			}
		}

		public let field: Field
		public let value: Value

		public init(field: Field, value: Value) {
			self.field = field
			self.value = value
		}
	}
}

extension [AccountPortfolio.NonFungibleResource.NonFungibleToken.NFTData] {
	public typealias Field = Self.Element.Field

	public subscript(field: Field) -> Self.Element.Value? {
		first { $0.field == field }?.value
	}

	public var name: String? {
		self[.name]?.string
	}

	public var keyImageURL: URL? {
		if let string = self[.keyImageURL]?.string {
			return URL(string: string)
		} else {
			return self[.keyImageURL]?.url
		}
	}

	public var tokenDescription: String? {
		self[.description]?.string
	}

	public var claimEpoch: UInt64? {
		self[.claimEpoch]?.u64
	}

	public var claimAmount: RETDecimal? {
		self[.claimAmount]?.decimal
	}
}
