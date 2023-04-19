import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponsePackageDetailsAllOf")
public typealias StateEntityDetailsResponsePackageDetailsAllOf = GatewayAPI.StateEntityDetailsResponsePackageDetailsAllOf

// MARK: - GatewayAPI.StateEntityDetailsResponsePackageDetailsAllOf
extension GatewayAPI {
	public struct StateEntityDetailsResponsePackageDetailsAllOf: Codable, Hashable {
		/** Hex-encoded binary blob. */
		public private(set) var codeHex: String?
		public private(set) var royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated?

		public init(codeHex: String? = nil, royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated? = nil) {
			self.codeHex = codeHex
			self.royaltyAggregator = royaltyAggregator
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case codeHex = "code_hex"
			case royaltyAggregator = "royalty_aggregator"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(codeHex, forKey: .codeHex)
			try container.encodeIfPresent(royaltyAggregator, forKey: .royaltyAggregator)
		}
	}
}
