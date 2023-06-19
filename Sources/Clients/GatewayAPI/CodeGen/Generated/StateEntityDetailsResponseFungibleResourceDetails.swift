//
// StateEntityDetailsResponseFungibleResourceDetails.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails")
public typealias StateEntityDetailsResponseFungibleResourceDetails = GatewayAPI.StateEntityDetailsResponseFungibleResourceDetails

extension GatewayAPI {

public struct StateEntityDetailsResponseFungibleResourceDetails: Codable, Hashable {

    public private(set) var accessRulesChain: AnyCodable
    public private(set) var vaultAccessRulesChain: AnyCodable
    public private(set) var divisibility: Int
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var totalSupply: String
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var totalMinted: String
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var totalBurned: String

    public init(accessRulesChain: AnyCodable, vaultAccessRulesChain: AnyCodable, divisibility: Int, totalSupply: String, totalMinted: String, totalBurned: String) {
        self.accessRulesChain = accessRulesChain
        self.vaultAccessRulesChain = vaultAccessRulesChain
        self.divisibility = divisibility
        self.totalSupply = totalSupply
        self.totalMinted = totalMinted
        self.totalBurned = totalBurned
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRulesChain = "access_rules_chain"
        case vaultAccessRulesChain = "vault_access_rules_chain"
        case divisibility
        case totalSupply = "total_supply"
        case totalMinted = "total_minted"
        case totalBurned = "total_burned"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessRulesChain, forKey: .accessRulesChain)
        try container.encode(vaultAccessRulesChain, forKey: .vaultAccessRulesChain)
        try container.encode(divisibility, forKey: .divisibility)
        try container.encode(totalSupply, forKey: .totalSupply)
        try container.encode(totalMinted, forKey: .totalMinted)
        try container.encode(totalBurned, forKey: .totalBurned)
    }
}

}
