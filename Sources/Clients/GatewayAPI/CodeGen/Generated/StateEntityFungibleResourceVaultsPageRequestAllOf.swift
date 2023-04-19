import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityFungibleResourceVaultsPageRequestAllOf")
public typealias StateEntityFungibleResourceVaultsPageRequestAllOf = GatewayAPI.StateEntityFungibleResourceVaultsPageRequestAllOf

// MARK: - GatewayAPI.StateEntityFungibleResourceVaultsPageRequestAllOf
extension GatewayAPI {
	public struct StateEntityFungibleResourceVaultsPageRequestAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String

		public init(address: String, resourceAddress: String) {
			self.address = address
			self.resourceAddress = resourceAddress
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case resourceAddress = "resource_address"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encode(resourceAddress, forKey: .resourceAddress)
		}
	}
}
