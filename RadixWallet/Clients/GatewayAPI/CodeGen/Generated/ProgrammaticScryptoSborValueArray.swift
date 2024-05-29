//
// ProgrammaticScryptoSborValueArray.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ProgrammaticScryptoSborValueArray")
public typealias ProgrammaticScryptoSborValueArray = GatewayAPI.ProgrammaticScryptoSborValueArray

extension GatewayAPI {

public struct ProgrammaticScryptoSborValueArray: Codable, Hashable {

    public private(set) var kind: ProgrammaticScryptoSborValueKind
    /** The name of the type of this value. This is only output when a schema is present and the type has a name. This property is ignored when the value is used as an input to the API.  */
    public private(set) var typeName: String?
    /** The name of the field which hosts this value. This property is only included if this value is a child of a `Tuple` or `Enum` with named fields. This property is ignored when the value is used as an input to the API.  */
    public private(set) var fieldName: String?
    public private(set) var elementKind: ProgrammaticScryptoSborValueKind
    public private(set) var elementTypeName: String?
    public private(set) var elements: [ProgrammaticScryptoSborValue]

    public init(kind: ProgrammaticScryptoSborValueKind, typeName: String? = nil, fieldName: String? = nil, elementKind: ProgrammaticScryptoSborValueKind, elementTypeName: String? = nil, elements: [ProgrammaticScryptoSborValue]) {
        self.kind = kind
        self.typeName = typeName
        self.fieldName = fieldName
        self.elementKind = elementKind
        self.elementTypeName = elementTypeName
        self.elements = elements
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case kind
        case typeName = "type_name"
        case fieldName = "field_name"
        case elementKind = "element_kind"
        case elementTypeName = "element_type_name"
        case elements
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(typeName, forKey: .typeName)
        try container.encodeIfPresent(fieldName, forKey: .fieldName)
        try container.encode(elementKind, forKey: .elementKind)
        try container.encodeIfPresent(elementTypeName, forKey: .elementTypeName)
        try container.encode(elements, forKey: .elements)
    }
}

}
