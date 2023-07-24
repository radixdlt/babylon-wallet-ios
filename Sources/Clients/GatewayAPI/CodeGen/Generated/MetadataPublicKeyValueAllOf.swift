//
// MetadataPublicKeyValueAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.MetadataPublicKeyValueAllOf")
public typealias MetadataPublicKeyValueAllOf = GatewayAPI.MetadataPublicKeyValueAllOf

extension GatewayAPI {

public struct MetadataPublicKeyValueAllOf: Codable, Hashable {

    public private(set) var value: PublicKey

    public init(value: PublicKey) {
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
}

}
