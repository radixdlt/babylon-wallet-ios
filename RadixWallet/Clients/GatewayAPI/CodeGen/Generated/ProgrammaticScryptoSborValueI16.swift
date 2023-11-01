//
// ProgrammaticScryptoSborValueI16.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ProgrammaticScryptoSborValueI16")
public typealias ProgrammaticScryptoSborValueI16 = GatewayAPI.ProgrammaticScryptoSborValueI16

extension GatewayAPI {

public struct ProgrammaticScryptoSborValueI16: Codable, Hashable {

    public private(set) var kind: ProgrammaticScryptoSborValueKind
    /** Object type name; available only when a schema is present and the type has a name. */
    public private(set) var typeName: String?
    /** Field name; available only when the value is a child of a `Tuple` or `Enum`, which has a type with named fields. */
    public private(set) var fieldName: String?
    public private(set) var value: String

    public init(kind: ProgrammaticScryptoSborValueKind, typeName: String? = nil, fieldName: String? = nil, value: String) {
        self.kind = kind
        self.typeName = typeName
        self.fieldName = fieldName
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case kind
        case typeName = "type_name"
        case fieldName = "field_name"
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(typeName, forKey: .typeName)
        try container.encodeIfPresent(fieldName, forKey: .fieldName)
        try container.encode(value, forKey: .value)
    }
}

}
