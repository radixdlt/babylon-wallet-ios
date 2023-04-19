import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponsePackageDetails")
public typealias StateEntityDetailsResponsePackageDetails = GatewayAPI.StateEntityDetailsResponsePackageDetails

// MARK: - GatewayAPI.StateEntityDetailsResponsePackageDetails
extension GatewayAPI {
	public struct StateEntityDetailsResponsePackageDetails: Codable, Hashable {
		public private(set) var type: StateEntityDetailsResponseItemDetailsType
		/** Hex-encoded binary blob. */
		public private(set) var codeHex: String?
		public private(set) var royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated?

		public init(type: StateEntityDetailsResponseItemDetailsType, codeHex: String? = nil, royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated? = nil) {
			self.type = type
			self.codeHex = codeHex
			self.royaltyAggregator = royaltyAggregator
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case codeHex = "code_hex"
			case royaltyAggregator = "royalty_aggregator"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encodeIfPresent(codeHex, forKey: .codeHex)
			try container.encodeIfPresent(royaltyAggregator, forKey: .royaltyAggregator)
		}
	}
}
