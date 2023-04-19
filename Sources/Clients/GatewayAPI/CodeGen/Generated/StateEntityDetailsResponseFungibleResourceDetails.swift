import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails")
public typealias StateEntityDetailsResponseFungibleResourceDetails = GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails

// MARK: - GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails
extension GatewayAPI {
	public struct StateEntityDetailsResponseFungibleResourceDetails: Codable, Hashable {
		public private(set) var type: StateEntityDetailsResponseItemDetailsType
		public private(set) var accessRulesChain: AnyCodable
		public private(set) var vaultAccessRulesChain: AnyCodable
		public private(set) var divisibility: Int

		public init(type: StateEntityDetailsResponseItemDetailsType, accessRulesChain: AnyCodable, vaultAccessRulesChain: AnyCodable, divisibility: Int) {
			self.type = type
			self.accessRulesChain = accessRulesChain
			self.vaultAccessRulesChain = vaultAccessRulesChain
			self.divisibility = divisibility
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case accessRulesChain = "access_rules_chain"
			case vaultAccessRulesChain = "vault_access_rules_chain"
			case divisibility
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
			try container.encode(accessRulesChain, forKey: .accessRulesChain)
			try container.encode(vaultAccessRulesChain, forKey: .vaultAccessRulesChain)
			try container.encode(divisibility, forKey: .divisibility)
		}
	}
}
