//
// MetadataBoolArrayValueAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataBoolArrayValueAllOf")
public typealias MetadataBoolArrayValueAllOf = GatewayAPI.MetadataBoolArrayValueAllOf

extension GatewayAPI {

public struct MetadataBoolArrayValueAllOf: Codable, Hashable {

    public private(set) var values: [Bool]

    public init(values: [Bool]) {
        self.values = values
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case values
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(values, forKey: .values)
    }
}

}
