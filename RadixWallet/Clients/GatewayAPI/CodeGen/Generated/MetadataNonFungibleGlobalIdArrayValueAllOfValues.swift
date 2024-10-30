//
// MetadataNonFungibleGlobalIdArrayValueAllOfValues.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataNonFungibleGlobalIdArrayValueAllOfValues")
typealias MetadataNonFungibleGlobalIdArrayValueAllOfValues = GatewayAPI.MetadataNonFungibleGlobalIdArrayValueAllOfValues

extension GatewayAPI {

struct MetadataNonFungibleGlobalIdArrayValueAllOfValues: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    private(set) var resourceAddress: String
    /** String-encoded non-fungible ID. */
    private(set) var nonFungibleId: String

    init(resourceAddress: String, nonFungibleId: String) {
        self.resourceAddress = resourceAddress
        self.nonFungibleId = nonFungibleId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case resourceAddress = "resource_address"
        case nonFungibleId = "non_fungible_id"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(nonFungibleId, forKey: .nonFungibleId)
    }
}

}
