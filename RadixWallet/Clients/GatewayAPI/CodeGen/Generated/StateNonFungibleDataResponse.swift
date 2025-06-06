//
// StateNonFungibleDataResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleDataResponse")
typealias StateNonFungibleDataResponse = GatewayAPI.StateNonFungibleDataResponse

extension GatewayAPI {

struct StateNonFungibleDataResponse: Codable, Hashable {

    private(set) var ledgerState: LedgerState
    /** Bech32m-encoded human readable version of the address. */
    private(set) var resourceAddress: String
    private(set) var nonFungibleIdType: NonFungibleIdType
    private(set) var nonFungibleIds: [StateNonFungibleDetailsResponseItem]

    init(ledgerState: LedgerState, resourceAddress: String, nonFungibleIdType: NonFungibleIdType, nonFungibleIds: [StateNonFungibleDetailsResponseItem]) {
        self.ledgerState = ledgerState
        self.resourceAddress = resourceAddress
        self.nonFungibleIdType = nonFungibleIdType
        self.nonFungibleIds = nonFungibleIds
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case resourceAddress = "resource_address"
        case nonFungibleIdType = "non_fungible_id_type"
        case nonFungibleIds = "non_fungible_ids"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(nonFungibleIdType, forKey: .nonFungibleIdType)
        try container.encode(nonFungibleIds, forKey: .nonFungibleIds)
    }
}

}
