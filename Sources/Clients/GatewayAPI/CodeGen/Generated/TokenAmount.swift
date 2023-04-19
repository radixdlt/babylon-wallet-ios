import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TokenAmount")
public typealias TokenAmount = GatewayAPI.TokenAmount

// MARK: - GatewayAPI.TokenAmount
extension GatewayAPI {
	/** Represents a decimal amount of a given resource. */
	public struct TokenAmount: Codable, Hashable {
		/** String-encoded decimal representing the amount of a related fungible resource. */
		public private(set) var value: String
		/** Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address or hex-encoded id. */
		public private(set) var address: String?

		public init(value: String, address: String? = nil) {
			self.value = value
			self.address = address
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case value
			case address
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(value, forKey: .value)
			try container.encodeIfPresent(address, forKey: .address)
		}
	}
}
