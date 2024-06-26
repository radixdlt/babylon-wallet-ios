//
// MetadataInstantArrayValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataInstantArrayValue")
public typealias MetadataInstantArrayValue = GatewayAPI.MetadataInstantArrayValue

extension GatewayAPI {

public struct MetadataInstantArrayValue: Codable, Hashable {

    public private(set) var type: MetadataValueType
    public private(set) var values: [String]
    public private(set) var valuesUnixTimestampSeconds: [String]

    public init(type: MetadataValueType, values: [String], valuesUnixTimestampSeconds: [String]) {
        self.type = type
        self.values = values
        self.valuesUnixTimestampSeconds = valuesUnixTimestampSeconds
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case values
        case valuesUnixTimestampSeconds = "values_unix_timestamp_seconds"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(values, forKey: .values)
        try container.encode(valuesUnixTimestampSeconds, forKey: .valuesUnixTimestampSeconds)
    }
}

}
