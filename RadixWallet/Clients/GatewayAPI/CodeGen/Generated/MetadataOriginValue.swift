//
// MetadataOriginValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataOriginValue")
typealias MetadataOriginValue = GatewayAPI.MetadataOriginValue

extension GatewayAPI {

struct MetadataOriginValue: Codable, Hashable {

    private(set) var type: MetadataValueType
    private(set) var value: String

    init(type: MetadataValueType, value: String) {
        self.type = type
        self.value = value
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case value
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
    }
}

}
