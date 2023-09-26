import EngineKit
import Foundation
import Prelude

// MARK: - OnLedgerEntity
public enum OnLedgerEntity: Sendable, Hashable, Codable {
	case resource(Resource)
	case nonFungibleToken(NonFungibleToken)

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
}

// MARK: OnLedgerEntity.Resource
extension OnLedgerEntity {
	public struct Resource: Sendable, Hashable, Codable, Identifiable {
		public var id: ResourceAddress { resourceAddress }
		public let resourceAddress: ResourceAddress
		public let divisibility: Int?
		public let behaviors: [AssetBehavior]
		public let totalSupply: BigDecimal?
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
			totalSupply: BigDecimal? = nil,
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
			description: String? = nil,
			keyImageURL: URL? = nil,
			metadata: [Metadata] = [],
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

extension OnLedgerEntity.NonFungibleToken {
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
			metadata: container.decode([OnLedgerEntity.Metadata].self, forKey: .metadata),
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
			case decimal(BigDecimal)
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

			var decimal: BigDecimal? {
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

	public var claimAmount: BigDecimal? {
		self[.claimAmount]?.decimal
	}
}
