import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetailsAllOf")
public typealias StateEntityDetailsResponseNonFungibleResourceDetailsAllOf = GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetailsAllOf

// MARK: - GatewayAPI.StateEntityDetailsResponseNonFungibleResourceDetailsAllOf
extension GatewayAPI {
	public struct StateEntityDetailsResponseNonFungibleResourceDetailsAllOf: Codable, Hashable {
		public private(set) var accessRulesChain: AnyCodable
		public private(set) var vaultAccessRulesChain: AnyCodable
		public private(set) var nonFungibleIdType: NonFungibleIdType

		public init(accessRulesChain: AnyCodable, vaultAccessRulesChain: AnyCodable, nonFungibleIdType: NonFungibleIdType) {
			self.accessRulesChain = accessRulesChain
			self.vaultAccessRulesChain = vaultAccessRulesChain
			self.nonFungibleIdType = nonFungibleIdType
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case accessRulesChain = "access_rules_chain"
			case vaultAccessRulesChain = "vault_access_rules_chain"
			case nonFungibleIdType = "non_fungible_id_type"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(accessRulesChain, forKey: .accessRulesChain)
			try container.encode(vaultAccessRulesChain, forKey: .vaultAccessRulesChain)
			try container.encode(nonFungibleIdType, forKey: .nonFungibleIdType)
		}
	}
}
