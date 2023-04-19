import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseComponentDetails")
public typealias StateEntityDetailsResponseComponentDetails = GatewayAPI.StateEntityDetailsResponseComponentDetails

// MARK: - GatewayAPI.StateEntityDetailsResponseComponentDetails
extension GatewayAPI {
	public struct StateEntityDetailsResponseComponentDetails: Codable, Hashable {
		public private(set) var type: StateEntityDetailsResponseItemDetailsType
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var packageAddress: String?
		public private(set) var blueprintName: String
		public private(set) var state: AnyCodable?
		public private(set) var accessRulesChain: AnyCodable
		public private(set) var royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated?

		public init(type: StateEntityDetailsResponseItemDetailsType, packageAddress: String? = nil, blueprintName: String, state: AnyCodable? = nil, accessRulesChain: AnyCodable, royaltyAggregator: FungibleResourcesCollectionItemGloballyAggregated? = nil) {
			self.type = type
			self.packageAddress = packageAddress
			self.blueprintName = blueprintName
			self.state = state
			self.accessRulesChain = accessRulesChain
			self.royaltyAggregator = royaltyAggregator
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case packageAddress = "package_address"
			case blueprintName = "blueprint_name"
			case state
			case accessRulesChain = "access_rules_chain"
			case royaltyAggregator = "royalty_aggregator"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encodeIfPresent(packageAddress, forKey: .packageAddress)
			try container.encode(blueprintName, forKey: .blueprintName)
			try container.encodeIfPresent(state, forKey: .state)
			try container.encode(accessRulesChain, forKey: .accessRulesChain)
			try container.encodeIfPresent(royaltyAggregator, forKey: .royaltyAggregator)
		}
	}
}
