//
// StateNonFungibleDataRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleDataRequest")
public typealias StateNonFungibleDataRequest = GatewayAPI.StateNonFungibleDataRequest

extension GatewayAPI {

public struct StateNonFungibleDataRequest: Codable, Hashable {

    public private(set) var atLedgerState: LedgerStateSelector?
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var resourceAddress: String
    public private(set) var nonFungibleIds: [String]

    public init(atLedgerState: LedgerStateSelector? = nil, resourceAddress: String, nonFungibleIds: [String]) {
        self.atLedgerState = atLedgerState
        self.resourceAddress = resourceAddress
        self.nonFungibleIds = nonFungibleIds
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case atLedgerState = "at_ledger_state"
        case resourceAddress = "resource_address"
        case nonFungibleIds = "non_fungible_ids"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(nonFungibleIds, forKey: .nonFungibleIds)
    }
}

}
