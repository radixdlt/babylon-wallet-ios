//
// CommittedTransactionsResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct CommittedTransactionsResponse: Codable, Hashable {

    /** An integer between 1 and 10^13, giving the first (resultant) state version in the returned response */
    public private(set) var fromStateVersion: Int64
    /** An integer between 1 and 10^13, giving the final (resultant) state version in the returned response */
    public private(set) var toStateVersion: Int64
    /** An integer between 1 and 10^13, giving the maximum state version currently committed */
    public private(set) var maxStateVersion: Int64
    /** A committed transactions list starting from the `from_state_version` (inclusive). */
    public private(set) var transactions: [CommittedTransaction]

    public init(fromStateVersion: Int64, toStateVersion: Int64, maxStateVersion: Int64, transactions: [CommittedTransaction]) {
        self.fromStateVersion = fromStateVersion
        self.toStateVersion = toStateVersion
        self.maxStateVersion = maxStateVersion
        self.transactions = transactions
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fromStateVersion = "from_state_version"
        case toStateVersion = "to_state_version"
        case maxStateVersion = "max_state_version"
        case transactions
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fromStateVersion, forKey: .fromStateVersion)
        try container.encode(toStateVersion, forKey: .toStateVersion)
        try container.encode(maxStateVersion, forKey: .maxStateVersion)
        try container.encode(transactions, forKey: .transactions)
    }
}

