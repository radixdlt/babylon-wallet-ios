//
// InvalidTransactionError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.InvalidTransactionError")
typealias InvalidTransactionError = GatewayAPI.InvalidTransactionError

extension GatewayAPI {

struct InvalidTransactionError: Codable, Hashable {

    /** The type of error. Each subtype may have its own additional structured fields. */
    private(set) var type: String

    init(type: String) {
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
}

}
