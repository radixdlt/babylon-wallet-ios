//
// StateAccountResourcePreferencesPageResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateAccountResourcePreferencesPageResponse")
public typealias StateAccountResourcePreferencesPageResponse = GatewayAPI.StateAccountResourcePreferencesPageResponse

extension GatewayAPI {

public struct StateAccountResourcePreferencesPageResponse: Codable, Hashable {

    public private(set) var ledgerState: LedgerState
    /** Total number of items in underlying collection, fragment of which is available in `items` collection. */
    public private(set) var totalCount: Int64?
    /** If specified, contains a cursor to query next page of the `items` collection. */
    public private(set) var nextCursor: String?
    public private(set) var items: [AccountResourcePreferencesResponseItem]
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accountAddress: String

    public init(ledgerState: LedgerState, totalCount: Int64? = nil, nextCursor: String? = nil, items: [AccountResourcePreferencesResponseItem], accountAddress: String) {
        self.ledgerState = ledgerState
        self.totalCount = totalCount
        self.nextCursor = nextCursor
        self.items = items
        self.accountAddress = accountAddress
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ledgerState = "ledger_state"
        case totalCount = "total_count"
        case nextCursor = "next_cursor"
        case items
        case accountAddress = "account_address"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ledgerState, forKey: .ledgerState)
        try container.encodeIfPresent(totalCount, forKey: .totalCount)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try container.encode(items, forKey: .items)
        try container.encode(accountAddress, forKey: .accountAddress)
    }
}

}
