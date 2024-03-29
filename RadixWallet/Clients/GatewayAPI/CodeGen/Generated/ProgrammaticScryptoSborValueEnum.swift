//
// ProgrammaticScryptoSborValueEnum.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ProgrammaticScryptoSborValueEnum")
public typealias ProgrammaticScryptoSborValueEnum = GatewayAPI.ProgrammaticScryptoSborValueEnum

extension GatewayAPI {

public struct ProgrammaticScryptoSborValueEnum: Codable, Hashable {

    public private(set) var kind: ProgrammaticScryptoSborValueKind
    /** Object type name; available only when a schema is present and the type has a name. */
    public private(set) var typeName: String?
    /** Field name; available only when the value is a child of a `Tuple` or `Enum`, which has a type with named fields. */
    public private(set) var fieldName: String?
    public private(set) var variantId: Int
    public private(set) var variantName: String?
    public private(set) var fields: [ProgrammaticScryptoSborValue]

    public init(kind: ProgrammaticScryptoSborValueKind, typeName: String? = nil, fieldName: String? = nil, variantId: Int, variantName: String? = nil, fields: [ProgrammaticScryptoSborValue]) {
        self.kind = kind
        self.typeName = typeName
        self.fieldName = fieldName
        self.variantId = variantId
        self.variantName = variantName
        self.fields = fields
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case kind
        case typeName = "type_name"
        case fieldName = "field_name"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case fields
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(typeName, forKey: .typeName)
        try container.encodeIfPresent(fieldName, forKey: .fieldName)
        try container.encode(variantId, forKey: .variantId)
        try container.encodeIfPresent(variantName, forKey: .variantName)
        try container.encode(fields, forKey: .fields)
    }
}

}
