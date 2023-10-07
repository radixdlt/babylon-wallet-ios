import EngineKit
import Foundation
import Prelude

// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable {
	case resource(Resource)
	case account(Account)
	case resourcePool(ResourcePool)
	case validator(Validator)
	case nonFungibleToken(NonFungibleToken)
	case accountNonFungibleIds(AccountNonFungibleIdsPage)

	public var resource: Resource? {
		guard case let .resource(resource) = self else {
			return nil
		}
		return resource
	}

	public var nonFungibleToken: NonFungibleToken? {
		guard case let .nonFungibleToken(nonFungibleToken) = self else {
			return nil
		}
		return nonFungibleToken
	}

	public var accountNonFungibleIds: AccountNonFungibleIdsPage? {
		guard case let .accountNonFungibleIds(ids) = self else {
			return nil
		}
		return ids
	}

	public var account: Account? {
		guard case let .account(account) = self else {
			return nil
		}
		return account
	}

	public var resourcePool: ResourcePool? {
		guard case let .resourcePool(resourcePool) = self else {
			return nil
		}
		return resourcePool
	}

	public var validator: Validator? {
		guard case let .validator(validator) = self else {
			return nil
		}
		return validator
	}
}

// MARK: OnLedgerEntity.Resource
extension OnLedgerEntity {
	public struct Resource: Sendable, Hashable, Codable, Identifiable {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let divisibility: Int?
		public let behaviors: [AssetBehavior]
		public let totalSupply: RETDecimal?
		public let resourceMetadata: ResourceMetadata

		public var fungibility: Fungibility {
			if case .globalFungibleResourceManager = resourceAddress.decodedKind {
				return .fungible
			} else {
				return .nonFungible
			}
		}

		public enum Fungibility {
			case fungible
			case nonFungible
		}

		public init(
			resourceAddress: ResourceAddress,
			divisibility: Int? = nil,
			behaviors: [AssetBehavior] = [],
			totalSupply: RETDecimal? = nil,
			resourceMetadata: ResourceMetadata
		) {
			self.resourceAddress = resourceAddress
			self.divisibility = divisibility
			self.behaviors = behaviors
			self.totalSupply = totalSupply
			self.resourceMetadata = resourceMetadata
		}
	}
}

extension OnLedgerEntity {
	public struct Metadata: Sendable, Hashable, Identifiable, Codable {
		public var id: String { key }
		public let key: String
		public let value: String

		public init(key: String, value: String) {
			self.key = key
			self.value = value
		}
	}

	public struct NonFungibleToken: Sendable, Hashable, Identifiable, Codable {
		public let id: NonFungibleGlobalId
		public let data: [NFTData]
		public let metadata: [Metadata]

		public init(
			id: NonFungibleGlobalId,
			data: [NFTData],
			metadata: [Metadata] = []
		) {
			self.id = id
			self.data = data
			self.metadata = metadata
		}
	}

	public struct AccountNonFungibleIdsPage: Sendable, Hashable, Codable {
		public let accountAddress: AccountAddress
		public let resourceAddress: ResourceAddress
		public let ids: [NonFungibleGlobalId]
		public let pageCursor: String?
		public let nextPageCursor: String?

		public init(
			accountAddress: AccountAddress,
			resourceAddress: ResourceAddress,
			ids: [NonFungibleGlobalId],
			pageCursor: String?,
			nextPageCursor: String?
		) {
			self.accountAddress = accountAddress
			self.resourceAddress = resourceAddress
			self.ids = ids
			self.pageCursor = pageCursor
			self.nextPageCursor = nextPageCursor
		}
	}
}

extension OnLedgerEntity {
	public struct ResourcePool: Sendable, Hashable, Codable {
		public let address: ResourcePoolAddress
		public let resources: [OwnedFungibleResource]
		public let metadata: ResourceMetadata

		public init(
			address: ResourcePoolAddress,
			resources: [OwnedFungibleResource],
			metadata: ResourceMetadata
		) {
			self.address = address
			self.resources = resources
			self.metadata = metadata
		}
	}

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
}

extension OnLedgerEntity {
	public struct OwnedFungibleResource: Sendable, Hashable, Identifiable, Codable {
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

	public struct OwnedNonFungibleResource: Sendable, Hashable, Identifiable, Codable {
		public var id: ResourceAddress {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public let atLedgerState: AtLedgerState
		public let metadata: ResourceMetadata
		public let nonFungibleIdsCount: Int
		/// The vault where the owned ids are stored
		public let vaultAddress: VaultAddress

		public init(
			resourceAddress: ResourceAddress,
			atLedgerState: AtLedgerState,
			metadata: ResourceMetadata,
			nonFungibleIdsCount: Int,
			vaultAddress: VaultAddress
		) {
			self.resourceAddress = resourceAddress
			self.atLedgerState = atLedgerState
			self.metadata = metadata
			self.nonFungibleIdsCount = nonFungibleIdsCount
			self.vaultAddress = vaultAddress
		}
	}
}

// MARK: OnLedgerEntity.Account
extension OnLedgerEntity {
	public struct Account: Sendable, Hashable, Codable {
		public let address: AccountAddress
		public let metadata: ResourceMetadata
		public var fungibleResources: [OwnedFungibleResource]
		public var nonFungibleResources: [OwnedNonFungibleResource]
		public var stakes: [RadixNetworkStake]
		public var poolUnits: [PoolUnit]

		public init(
			address: AccountAddress,
			metadata: ResourceMetadata,
			fungibleResources: [OwnedFungibleResource],
			nonFungibleResources: [OwnedNonFungibleResource],
			stakes: [RadixNetworkStake],
			poolUnits: [PoolUnit]
		) {
			self.address = address
			self.metadata = metadata
			self.fungibleResources = fungibleResources
			self.nonFungibleResources = nonFungibleResources
			self.stakes = stakes
			self.poolUnits = poolUnits
		}
	}
}

extension OnLedgerEntity.Account {
	public struct RadixNetworkStake: Sendable, Hashable, Codable {
		public let validatorAddress: ValidatorAddress
		public let stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?
		public let stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?

		public init(
			validatorAddress: ValidatorAddress,
			stakeUnitResource: OnLedgerEntity.OwnedFungibleResource?,
			stakeClaimResource: OnLedgerEntity.OwnedNonFungibleResource?
		) {
			self.validatorAddress = validatorAddress
			self.stakeUnitResource = stakeUnitResource
			self.stakeClaimResource = stakeClaimResource
		}
	}

	public struct PoolUnit: Sendable, Hashable, Codable {
		public let resource: OnLedgerEntity.OwnedFungibleResource
		public let resourcePoolAddress: ResourcePoolAddress

		public init(
			resource: OnLedgerEntity.OwnedFungibleResource,
			resourcePoolAddress: ResourcePoolAddress
		) {
			self.resource = resource
			self.resourcePoolAddress = resourcePoolAddress
		}
	}
}

extension OnLedgerEntity.NonFungibleToken {
	enum CodingKeys: CodingKey {
		case id
		case data
		case metadata
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			id: .init(nonFungibleGlobalId: container.decode(String.self, forKey: .id)),
			data: container.decode([NFTData].self, forKey: .data),
			metadata: container.decode([OnLedgerEntity.Metadata].self, forKey: .metadata)
		)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id.asStr(), forKey: .id)
		try container.encode(data, forKey: .data)
		try container.encode(metadata, forKey: .metadata)
	}
}

// MARK: - OnLedgerEntity.NonFungibleToken.NFTData
extension OnLedgerEntity.NonFungibleToken {
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

extension [OnLedgerEntity.NonFungibleToken.NFTData] {
	public subscript(field: OnLedgerEntity.NonFungibleToken.NFTData.Field) -> OnLedgerEntity.NonFungibleToken.NFTData.Value? {
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
