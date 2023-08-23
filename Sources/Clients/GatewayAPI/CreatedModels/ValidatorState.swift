import Foundation

extension GatewayAPI {
	struct Entity: Codable {
		let entityAddress: String

		enum CodingKeys: String, CodingKey {
			case entityAddress = "entity_address"
		}
	}

	public struct ValidatorState: Codable, Hashable, EmptyObjectDecodable {
		public let stakeUnitResourceAddress: String
		public let stakeXRDVaultAddress: String
		public let unstakeClaimTokenResourceAddress: String

		public enum CodingKeys: String, CodingKey {
			case stakeXRDVaultAddress = "stake_xrd_vault"
			case stakeUnitResourceAddress = "stake_unit_resource_address"
			case unstakeClaimTokenResourceAddress = "claim_token_resource_address"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.stakeXRDVaultAddress = try container.decode(Entity.self, forKey: .stakeXRDVaultAddress).entityAddress

			self.stakeUnitResourceAddress = try container.decode(String.self, forKey: .stakeUnitResourceAddress)
			self.unstakeClaimTokenResourceAddress = try container.decode(String.self, forKey: .unstakeClaimTokenResourceAddress)
		}
	}
}

// MARK: - EmptyObjectDecodable
public protocol EmptyObjectDecodable {
	associatedtype CodingKeys: RawRepresentable where CodingKeys.RawValue == String
	associatedtype CodingKeyType: CodingKey = Self.CodingKeys
}

extension KeyedDecodingContainer {
	public func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T?
		where T: Decodable & EmptyObjectDecodable
	{
		guard contains(key) else { return nil }
		let container = try nestedContainer(keyedBy: type.CodingKeyType.self, forKey: key)
		return container.allKeys.isEmpty ? nil : try decode(T.self, forKey: key)
	}
}
