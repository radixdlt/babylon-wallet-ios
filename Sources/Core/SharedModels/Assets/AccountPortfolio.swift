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
			// Indication that stake unit amount can be claimed if it is stake claim nft
			public let canBeClaimed: Bool

			public init(
				id: NonFungibleGlobalId,
				name: String?,
				description: String?,
				keyImageURL: URL?,
				metadata: [Metadata],
				stakeClaimAmount: BigDecimal? = nil,
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

		public func redemptionValue(for resource: AccountPortfolio.FungibleResource) -> BigDecimal {
			let poolUnitTotalSupply = poolUnitResource.totalSupply ?? .one
			let unroundedRedemptionValue = poolUnitResource.amount * resource.amount / poolUnitTotalSupply
			return resource.divisibility.map { unroundedRedemptionValue.withPrecision($0) } ?? unroundedRedemptionValue
		}
	}

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
		public let stakeUnitResource: AccountPortfolio.FungibleResource?
		public let stakeClaimResource: AccountPortfolio.NonFungibleResource?

		public var xrdRedemptionValue: BigDecimal? {
			guard let stakeUnitResource else {
				return nil
			}
			return (stakeUnitResource.amount * validator.xrdVaultBalance) / (stakeUnitResource.totalSupply ?? .one)
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
			case keyImageURL
			case claimEpoch
			case claimAmount

			public init?(rawValue: String) {
				switch rawValue {
				case "name":
					self = .name
				case "description":
					self = .description
				case "key_image_url":
					self = .keyImageURL
				case "claim_epoch":
					self = .claimEpoch
				case "claim_amount":
					self = .claimAmount
				default:
					return nil
				}
			}
		}

		public enum Value: Sendable, Hashable, Codable {
			case string(String)
			case url(URL)
			case decimal(BigDecimal)
			case u64(UInt64)

			var asString: String? {
				guard case let .string(str) = self else {
					return nil
				}
				return str
			}

			var asURL: URL? {
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

			var decimal: BigDecimal? {
				guard case let .decimal(decimal) = self else {
					return nil
				}
				return decimal
			}

			public init?(typeName: String, value: JSONValue) {
				switch typeName {
				case "String":
					guard let str = value.string else {
						return nil
					}
					self = .string(str)
				case "Url":
					guard let url = value.string.flatMap(URL.init) else {
						return nil
					}
					self = .url(url)
				case "U64":
					guard let u64 = value.uint.map(UInt64.init) else {
						return nil
					}
					self = .u64(u64)
				case "Decimal":
					guard let decimal = try? value.string.map(BigDecimal.init(fromString:)) else {
						return nil
					}
					self = .decimal(decimal)
				default:
					return nil
				}
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
		self[.name]?.asString
	}

	public var keyImageURL: URL? {
		self[.keyImageURL]?.asURL
	}

	public var claimEpoch: UInt64? {
		self[.claimEpoch]?.u64
	}

	public var claimAmount: BigDecimal? {
		self[.claimAmount]?.decimal
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
		try container.encode(canBeClaimed, forKey: .canBeClaimed)
	}
}
