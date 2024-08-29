//
// NativeResourceXrdValue.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NativeResourceXrdValue")
public typealias NativeResourceXrdValue = GatewayAPI.NativeResourceXrdValue

extension GatewayAPI {

public struct NativeResourceXrdValue: Codable, Hashable {

    public private(set) var kind: NativeResourceKind

    public init(kind: NativeResourceKind) {
        self.kind = kind
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case kind
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
    }
}

}
