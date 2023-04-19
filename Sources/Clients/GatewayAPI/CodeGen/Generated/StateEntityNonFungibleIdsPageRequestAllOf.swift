import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityNonFungibleIdsPageRequestAllOf")
public typealias StateEntityNonFungibleIdsPageRequestAllOf = GatewayAPI.StateEntityNonFungibleIdsPageRequestAllOf

// MARK: - GatewayAPI.StateEntityNonFungibleIdsPageRequestAllOf
extension GatewayAPI {
	public struct StateEntityNonFungibleIdsPageRequestAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var vaultAddress: String
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String

		public init(address: String, vaultAddress: String, resourceAddress: String) {
			self.address = address
			self.vaultAddress = vaultAddress
			self.resourceAddress = resourceAddress
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case vaultAddress = "vault_address"
			case resourceAddress = "resource_address"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encode(vaultAddress, forKey: .vaultAddress)
			try container.encode(resourceAddress, forKey: .resourceAddress)
		}
	}
}
