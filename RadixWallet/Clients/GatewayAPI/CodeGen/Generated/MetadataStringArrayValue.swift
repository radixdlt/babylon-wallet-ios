//
// MetadataStringArrayValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataStringArrayValue")
typealias MetadataStringArrayValue = GatewayAPI.MetadataStringArrayValue

extension GatewayAPI {

struct MetadataStringArrayValue: Codable, Hashable {

    private(set) var type: MetadataValueType
    private(set) var values: [String]

    init(type: MetadataValueType, values: [String]) {
        self.type = type
        self.values = values
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case values
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(values, forKey: .values)
    }
}

}
