//
// MetadataI32Value.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataI32Value")
public typealias MetadataI32Value = GatewayAPI.MetadataI32Value

extension GatewayAPI {

public struct MetadataI32Value: Codable, Hashable {

    public private(set) var type: MetadataValueType
    public private(set) var value: String

    public init(type: MetadataValueType, value: String) {
        self.type = type
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
    }
}

}
