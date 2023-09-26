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
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let amount: BigDecimal
		public let metadata: ResourceMetadata

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			amount: BigDecimal,
			metadata: ResourceMetadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.amount = amount
			self.metadata = metadata
		}
	}

	public struct NonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let nonFungibleIds: [NonFungibleGlobalId]
		public let metadata: ResourceMetadata

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			nonFungibleIds: [NonFungibleGlobalId],
			metadata: ResourceMetadata
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.nonFungibleIds = nonFungibleIds
			self.metadata = metadata
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
			fatalError()
//			let poolUnitTotalSupply = poolUnitResource.resource.totalSupply ?? .one
//			let unroundedRedemptionValue = poolUnitResource.amount * resource.amount / poolUnitTotalSupply
//			return unroundedRedemptionValue.format(divisibility: resource.resource.divisibility)
		}
	}

	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public struct Validator: Sendable, Hashable, Codable {
			public let address: ValidatorAddress
			public let xrdVaultBalance: BigDecimal
			public let metadata: ResourceMetadata

			public init(
				address: ValidatorAddress,
				xrdVaultBalance: BigDecimal,
				metadata: ResourceMetadata
			) {
				self.address = address
				self.xrdVaultBalance = xrdVaultBalance
				self.metadata = metadata
			}
		}

		public let validator: Validator
		public let stakeUnitResource: AccountPortfolio.FungibleResource?
		public let stakeClaimResource: AccountPortfolio.NonFungibleResource?

		public var xrdRedemptionValue: BigDecimal? {
			guard let stakeUnitResource else {
				return nil
			}
			fatalError()
			// return (stakeUnitResource.amount * validator.xrdVaultBalance) / (stakeUnitResource.resource.totalSupply ?? .one)
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
		nonFungibleIds.isEmpty ? nil : self
	}
}

extension AccountPortfolio.NonFungibleResource {
	enum CodingKeys: CodingKey {
		case resourceAddress
		case atLedgerState
		case tokens
		case metadata
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			atLedgerState: container.decode(AtLedgerState.self, forKey: .atLedgerState),
			nonFungibleIds: container.decode([String].self, forKey: .tokens).map(NonFungibleGlobalId.init(nonFungibleGlobalId:)),
			metadata: container.decode(ResourceMetadata.self, forKey: .metadata)
		)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(atLedgerState, forKey: .atLedgerState)
		try container.encode(nonFungibleIds.map { $0.asStr() }, forKey: .tokens)
		try container.encode(metadata, forKey: .metadata)
	}
}
