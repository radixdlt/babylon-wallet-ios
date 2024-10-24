//
// TransactionDetailsOptIns.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionDetailsOptIns")
typealias TransactionDetailsOptIns = GatewayAPI.TransactionDetailsOptIns

extension GatewayAPI {

struct TransactionDetailsOptIns: Codable, Hashable {

    /** if set to `true`, raw transaction hex is returned. */
    private(set) var rawHex: Bool? = false
    /** if set to `true`, state changes inside receipt object are returned. */
    private(set) var receiptStateChanges: Bool? = false
    /** if set to `true`, fee summary inside receipt object is returned. */
    private(set) var receiptFeeSummary: Bool? = false
    /** if set to `true`, fee source inside receipt object is returned. */
    private(set) var receiptFeeSource: Bool? = false
    /** if set to `true`, fee destination inside receipt object is returned. */
    private(set) var receiptFeeDestination: Bool? = false
    /** if set to `true`, costing parameters inside receipt object is returned. */
    private(set) var receiptCostingParameters: Bool? = false
    /** if set to `true`, events inside receipt object is returned. */
    private(set) var receiptEvents: Bool? = false
    /** (true by default) if set to `true`, transaction receipt output is returned. */
    private(set) var receiptOutput: Bool? = true
    /** if set to `true`, all affected global entities by given transaction are returned. */
    private(set) var affectedGlobalEntities: Bool? = false
    /** if set to `true`, manifest instructions for user transactions are returned. */
    private(set) var manifestInstructions: Bool? = false
    /** if set to `true`, returns the fungible and non-fungible balance changes.  **Warning!** This opt-in might be missing for recently committed transactions, in that case a `null` value will be returned. Retry the request until non-null value is returned.  */
    private(set) var balanceChanges: Bool? = false

    init(rawHex: Bool? = false, receiptStateChanges: Bool? = false, receiptFeeSummary: Bool? = false, receiptFeeSource: Bool? = false, receiptFeeDestination: Bool? = false, receiptCostingParameters: Bool? = false, receiptEvents: Bool? = false, receiptOutput: Bool? = true, affectedGlobalEntities: Bool? = false, manifestInstructions: Bool? = false, balanceChanges: Bool? = false) {
        self.rawHex = rawHex
        self.receiptStateChanges = receiptStateChanges
        self.receiptFeeSummary = receiptFeeSummary
        self.receiptFeeSource = receiptFeeSource
        self.receiptFeeDestination = receiptFeeDestination
        self.receiptCostingParameters = receiptCostingParameters
        self.receiptEvents = receiptEvents
        self.receiptOutput = receiptOutput
        self.affectedGlobalEntities = affectedGlobalEntities
        self.manifestInstructions = manifestInstructions
        self.balanceChanges = balanceChanges
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case rawHex = "raw_hex"
        case receiptStateChanges = "receipt_state_changes"
        case receiptFeeSummary = "receipt_fee_summary"
        case receiptFeeSource = "receipt_fee_source"
        case receiptFeeDestination = "receipt_fee_destination"
        case receiptCostingParameters = "receipt_costing_parameters"
        case receiptEvents = "receipt_events"
        case receiptOutput = "receipt_output"
        case affectedGlobalEntities = "affected_global_entities"
        case manifestInstructions = "manifest_instructions"
        case balanceChanges = "balance_changes"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(rawHex, forKey: .rawHex)
        try container.encodeIfPresent(receiptStateChanges, forKey: .receiptStateChanges)
        try container.encodeIfPresent(receiptFeeSummary, forKey: .receiptFeeSummary)
        try container.encodeIfPresent(receiptFeeSource, forKey: .receiptFeeSource)
        try container.encodeIfPresent(receiptFeeDestination, forKey: .receiptFeeDestination)
        try container.encodeIfPresent(receiptCostingParameters, forKey: .receiptCostingParameters)
        try container.encodeIfPresent(receiptEvents, forKey: .receiptEvents)
        try container.encodeIfPresent(receiptOutput, forKey: .receiptOutput)
        try container.encodeIfPresent(affectedGlobalEntities, forKey: .affectedGlobalEntities)
        try container.encodeIfPresent(manifestInstructions, forKey: .manifestInstructions)
        try container.encodeIfPresent(balanceChanges, forKey: .balanceChanges)
    }
}

}
