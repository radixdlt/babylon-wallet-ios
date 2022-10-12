//
// TargetLedgerState.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct TargetLedgerState: Sendable, Codable, Hashable {

    /** The latest-seen state version of the tip of the network's ledger. If this is singificantly ahead of the current LedgerState version, the Network Gateway is possibly behind and may be reporting outdated information.  */
    public let version: Int64

    public init(version: Int64) {
        self.version = version
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case version
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
    }
}

