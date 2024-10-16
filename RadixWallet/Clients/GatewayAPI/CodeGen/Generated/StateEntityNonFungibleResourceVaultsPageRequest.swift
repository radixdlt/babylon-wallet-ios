//
// StateEntityNonFungibleResourceVaultsPageRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest")
typealias StateEntityNonFungibleResourceVaultsPageRequest = GatewayAPI.StateEntityNonFungibleResourceVaultsPageRequest

extension GatewayAPI {

struct StateEntityNonFungibleResourceVaultsPageRequest: Codable, Hashable {

    private(set) var atLedgerState: LedgerStateSelector?
    /** This cursor allows forward pagination, by providing the cursor from the previous request. */
    private(set) var cursor: String?
    /** The page size requested. */
    private(set) var limitPerPage: Int?
    /** Bech32m-encoded human readable version of the address. */
    private(set) var address: String
    /** Bech32m-encoded human readable version of the address. */
    private(set) var resourceAddress: String
    private(set) var optIns: StateEntityNonFungibleResourceVaultsPageOptIns?

    init(atLedgerState: LedgerStateSelector? = nil, cursor: String? = nil, limitPerPage: Int? = nil, address: String, resourceAddress: String, optIns: StateEntityNonFungibleResourceVaultsPageOptIns? = nil) {
        self.atLedgerState = atLedgerState
        self.cursor = cursor
        self.limitPerPage = limitPerPage
        self.address = address
        self.resourceAddress = resourceAddress
        self.optIns = optIns
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case atLedgerState = "at_ledger_state"
        case cursor
        case limitPerPage = "limit_per_page"
        case address
        case resourceAddress = "resource_address"
        case optIns = "opt_ins"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
        try container.encodeIfPresent(cursor, forKey: .cursor)
        try container.encodeIfPresent(limitPerPage, forKey: .limitPerPage)
        try container.encode(address, forKey: .address)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encodeIfPresent(optIns, forKey: .optIns)
    }
}

}
