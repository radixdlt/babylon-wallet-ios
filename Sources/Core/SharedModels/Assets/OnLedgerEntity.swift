import EngineKit
import Foundation
import Prelude

// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable {
	case resource(Resource)
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
