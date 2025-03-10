//
// StateEntityDetailsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsRequest")
typealias StateEntityDetailsRequest = GatewayAPI.StateEntityDetailsRequest

extension GatewayAPI {

struct StateEntityDetailsRequest: Codable, Hashable {

    private(set) var atLedgerState: LedgerStateSelector?
    private(set) var optIns: StateEntityDetailsOptIns?
    /** limited to max 20 items. */
    private(set) var addresses: [String]
    private(set) var aggregationLevel: ResourceAggregationLevel?

    init(atLedgerState: LedgerStateSelector? = nil, optIns: StateEntityDetailsOptIns? = nil, addresses: [String], aggregationLevel: ResourceAggregationLevel? = nil) {
        self.atLedgerState = atLedgerState
        self.optIns = optIns
        self.addresses = addresses
        self.aggregationLevel = aggregationLevel
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case atLedgerState = "at_ledger_state"
        case optIns = "opt_ins"
        case addresses
        case aggregationLevel = "aggregation_level"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
        try container.encodeIfPresent(optIns, forKey: .optIns)
        try container.encode(addresses, forKey: .addresses)
        try container.encodeIfPresent(aggregationLevel, forKey: .aggregationLevel)
    }
}

}
