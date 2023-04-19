import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidEntityError")
public typealias InvalidEntityError = GatewayAPI.InvalidEntityError

// MARK: - GatewayAPI.InvalidEntityError
extension GatewayAPI {
	public struct InvalidEntityError: Codable, Hashable {
		/** The type of error. Each subtype may have its own additional structured fields. */
		public private(set) var type: String
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var address: String

		public init(type: String, address: String) {
			self.type = type
			self.address = address
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case address
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(address, forKey: .address)
		}
	}
}
