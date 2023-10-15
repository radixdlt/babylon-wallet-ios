//
// EntityMetadataItemValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataItemValue")
public typealias EntityMetadataItemValue = GatewayAPI.EntityMetadataItemValue

extension GatewayAPI {

public struct EntityMetadataItemValue: Codable, Hashable {

    public private(set) var rawHex: String
    public private(set) var programmaticJson: AnyCodable
    public private(set) var typed: MetadataTypedValue

    public init(rawHex: String, programmaticJson: AnyCodable, typed: MetadataTypedValue) {
        self.rawHex = rawHex
        self.programmaticJson = programmaticJson
        self.typed = typed
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rawHex = "raw_hex"
        case programmaticJson = "programmatic_json"
        case typed
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawHex, forKey: .rawHex)
        try container.encode(programmaticJson, forKey: .programmaticJson)
        try container.encode(typed, forKey: .typed)
    }
}

}
