import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleIdsRequestAllOf")
public typealias StateNonFungibleIdsRequestAllOf = GatewayAPI.StateNonFungibleIdsRequestAllOf

// MARK: - GatewayAPI.StateNonFungibleIdsRequestAllOf
extension GatewayAPI {
	public struct StateNonFungibleIdsRequestAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var resourceAddress: String

		public init(resourceAddress: String) {
			self.resourceAddress = resourceAddress
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case resourceAddress = "resource_address"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(resourceAddress, forKey: .resourceAddress)
		}
	}
}
