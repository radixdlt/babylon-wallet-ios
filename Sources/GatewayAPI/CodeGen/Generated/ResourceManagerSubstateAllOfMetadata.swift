//
// ResourceManagerSubstateAllOfMetadata.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct ResourceManagerSubstateAllOfMetadata: Codable, Hashable {

    public private(set) var key: String
    public private(set) var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case key
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
    }
}

