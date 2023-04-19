import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityMetadataPageRequestAllOf")
public typealias StateEntityMetadataPageRequestAllOf = GatewayAPI.StateEntityMetadataPageRequestAllOf

// MARK: - GatewayAPI.StateEntityMetadataPageRequestAllOf
extension GatewayAPI {
	public struct StateEntityMetadataPageRequestAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String

		public init(address: String) {
			self.address = address
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
		}
	}
}
