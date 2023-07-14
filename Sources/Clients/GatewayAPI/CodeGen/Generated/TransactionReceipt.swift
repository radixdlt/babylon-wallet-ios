//
// TransactionReceipt.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionReceipt")
public typealias TransactionReceipt = GatewayAPI.TransactionReceipt

extension GatewayAPI {

public struct TransactionReceipt: Codable, Hashable {

    /** The status of the transaction. */
    public private(set) var status: AnyCodable?
    /** Fees paid, Only present if the `status` is not `Rejected`. */
    public private(set) var feeSummary: AnyCodable?
    /** Transaction state updates (only present if status is Succeeded or Failed). */
    public private(set) var stateUpdates: AnyCodable?
    /** Information (number and active validator list) about new epoch if occured. */
    public private(set) var nextEpoch: AnyCodable?
    /** The manifest line-by-line engine return data (only present if `status` is `Succeeded`). */
    public private(set) var output: AnyCodable?
    /** Events emitted by a transaction. */
    public private(set) var events: AnyCodable?
    /** Error message (only present if status is `Failed` or `Rejected`) */
    public private(set) var errorMessage: String?

    public init(status: AnyCodable? = nil, feeSummary: AnyCodable? = nil, stateUpdates: AnyCodable? = nil, nextEpoch: AnyCodable? = nil, output: AnyCodable? = nil, events: AnyCodable? = nil, errorMessage: String? = nil) {
        self.status = status
        self.feeSummary = feeSummary
        self.stateUpdates = stateUpdates
        self.nextEpoch = nextEpoch
        self.output = output
        self.events = events
        self.errorMessage = errorMessage
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case status
        case feeSummary = "fee_summary"
        case stateUpdates = "state_updates"
        case nextEpoch = "next_epoch"
        case output
        case events
        case errorMessage = "error_message"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(feeSummary, forKey: .feeSummary)
        try container.encodeIfPresent(stateUpdates, forKey: .stateUpdates)
        try container.encodeIfPresent(nextEpoch, forKey: .nextEpoch)
        try container.encodeIfPresent(output, forKey: .output)
        try container.encodeIfPresent(events, forKey: .events)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }
}

}
