//
// TransactionSubmitResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionSubmitResponse")
typealias TransactionSubmitResponse = GatewayAPI.TransactionSubmitResponse

extension GatewayAPI {

struct TransactionSubmitResponse: Codable, Hashable {

    /** Is true if the transaction is a duplicate of an existing pending transaction. */
    private(set) var duplicate: Bool

    init(duplicate: Bool) {
        self.duplicate = duplicate
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duplicate
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duplicate, forKey: .duplicate)
    }
}

}
