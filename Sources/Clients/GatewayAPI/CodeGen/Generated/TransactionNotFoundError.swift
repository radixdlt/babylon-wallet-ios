//
// TransactionNotFoundError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionNotFoundError")
public typealias TransactionNotFoundError = GatewayAPI.TransactionNotFoundError

extension GatewayAPI {

public struct TransactionNotFoundError: Codable, Hashable {

    /** The type of error. Each subtype may have its own additional structured fields. */
    public private(set) var type: String
    /** Bech32m-encoded hash. */
    public private(set) var intentHash: String

    public init(type: String, intentHash: String) {
        self.type = type
        self.intentHash = intentHash
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case intentHash = "intent_hash"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(intentHash, forKey: .intentHash)
    }
}

}
