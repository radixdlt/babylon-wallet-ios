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
		public let amount: RETDecimal
		public let metadata: ResourceMetadata

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			amount: RETDecimal,
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

//		public func redemptionValue(for resource: AccountPortfolio.FungibleResource) -> String {
//			guard let poolUnitTotalSupply = poolUnitResource.resource.totalSupply else {
//				loggerGlobal.error("Missing total supply for \(resource.resourceAddress.address)")
//				return "Missing Total supply - could not calculate redemption value" // FIXME: Strings
//			}
//			let redemptionValue = poolUnitResource.amount * (resource.amount / poolUnitTotalSupply)
//			let decimalPlaces = resource.resource.divisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
//			let roundedRedemptionValue = redemptionValue.rounded(decimalPlaces: decimalPlaces)
//
//			return roundedRedemptionValue.formatted()
//		}
	}

	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public struct Validator: Sendable, Hashable, Codable {
			public let address: ValidatorAddress
			public let xrdVaultBalance: RETDecimal
			public let metadata: ResourceMetadata

			public init(
				address: ValidatorAddress,
				xrdVaultBalance: RETDecimal,
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

//		public var xrdRedemptionValue: RETDecimal? {
//			guard let stakeUnitResource, let totalSupply = stakeUnitResource.resource.totalSupply else {
//				return nil
//			}
//			return validator.xrdVaultBalance * (stakeUnitResource.amount / totalSupply)
//		}

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
