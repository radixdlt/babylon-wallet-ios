//
// StateKeyValueStoreDataResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateKeyValueStoreDataResponse")
typealias StateKeyValueStoreDataResponse = GatewayAPI.StateKeyValueStoreDataResponse

extension GatewayAPI {

struct StateKeyValueStoreDataResponse: Codable, Hashable {

    private(set) var ledgerState: LedgerState
    /** Bech32m-encoded human readable version of the address. */
    private(set) var keyValueStoreAddress: String
    private(set) var entries: [StateKeyValueStoreDataResponseItem]

    init(ledgerState: LedgerState, keyValueStoreAddress: String, entries: [StateKeyValueStoreDataResponseItem]) {
        self.ledgerState = ledgerState
        self.keyValueStoreAddress = keyValueStoreAddress
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case keyValueStoreAddress = "key_value_store_address"
        case entries
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encode(keyValueStoreAddress, forKey: .keyValueStoreAddress)
        try container.encode(entries, forKey: .entries)
    }
}

}
