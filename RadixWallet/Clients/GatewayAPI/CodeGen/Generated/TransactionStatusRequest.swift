//
// TransactionStatusRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusRequest")
typealias TransactionStatusRequest = GatewayAPI.TransactionStatusRequest

extension GatewayAPI {

struct TransactionStatusRequest: Codable, Hashable {

    /** Bech32m-encoded hash. */
    private(set) var intentHash: String

    init(intentHash: String) {
        self.intentHash = intentHash
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case intentHash = "intent_hash"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intentHash, forKey: .intentHash)
    }
}

}
