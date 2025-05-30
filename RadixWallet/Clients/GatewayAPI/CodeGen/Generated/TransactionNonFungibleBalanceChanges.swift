//
// TransactionNonFungibleBalanceChanges.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionNonFungibleBalanceChanges")
typealias TransactionNonFungibleBalanceChanges = GatewayAPI.TransactionNonFungibleBalanceChanges

extension GatewayAPI {

struct TransactionNonFungibleBalanceChanges: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    private(set) var entityAddress: String
    /** Bech32m-encoded human readable version of the address. */
    private(set) var resourceAddress: String
    private(set) var added: [String]
    private(set) var removed: [String]

    init(entityAddress: String, resourceAddress: String, added: [String], removed: [String]) {
        self.entityAddress = entityAddress
        self.resourceAddress = resourceAddress
        self.added = added
        self.removed = removed
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case entityAddress = "entity_address"
        case resourceAddress = "resource_address"
        case added
        case removed
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityAddress, forKey: .entityAddress)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(added, forKey: .added)
        try container.encode(removed, forKey: .removed)
    }
}

}
