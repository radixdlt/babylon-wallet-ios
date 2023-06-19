//
// StateEntityDetailsResponsePackageDetails.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponsePackageDetails")
public typealias StateEntityDetailsResponsePackageDetails = GatewayAPI.StateEntityDetailsResponsePackageDetails

extension GatewayAPI {

public struct StateEntityDetailsResponsePackageDetails: Codable, Hashable {

    /** Hex-encoded binary blob. */
    public private(set) var codeHex: String?
    /** String-encoded decimal representing the amount of a related fungible resource. */
    public private(set) var royaltyVaultBalance: String?

    public init(codeHex: String? = nil, royaltyVaultBalance: String? = nil) {
        self.codeHex = codeHex
        self.royaltyVaultBalance = royaltyVaultBalance
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case codeHex = "code_hex"
        case royaltyVaultBalance = "royalty_vault_balance"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(codeHex, forKey: .codeHex)
        try container.encodeIfPresent(royaltyVaultBalance, forKey: .royaltyVaultBalance)
    }
}

}
