//
// EntitySchemaCollectionItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntitySchemaCollectionItem")
typealias EntitySchemaCollectionItem = GatewayAPI.EntitySchemaCollectionItem

extension GatewayAPI {

struct EntitySchemaCollectionItem: Codable, Hashable {

    /** Hex-encoded binary blob. */
    private(set) var schemaHashHex: String
    /** Hex-encoded binary blob. */
    private(set) var schemaHex: String

    init(schemaHashHex: String, schemaHex: String) {
        self.schemaHashHex = schemaHashHex
        self.schemaHex = schemaHex
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case schemaHashHex = "schema_hash_hex"
        case schemaHex = "schema_hex"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaHashHex, forKey: .schemaHashHex)
        try container.encode(schemaHex, forKey: .schemaHex)
    }
}

}
