//
// EntityReference.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityReference")
public typealias EntityReference = GatewayAPI.EntityReference

extension GatewayAPI {

public struct EntityReference: Codable, Hashable {

    public private(set) var entityType: EntityType
    public private(set) var isGlobal: Bool
    /** Bech32m-encoded human readable version of the entity's address (ie the entity's node id) */
    public private(set) var entityAddress: String

    public init(entityType: EntityType, isGlobal: Bool, entityAddress: String) {
        self.entityType = entityType
        self.isGlobal = isGlobal
        self.entityAddress = entityAddress
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case entityType = "entity_type"
        case isGlobal = "is_global"
        case entityAddress = "entity_address"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(isGlobal, forKey: .isGlobal)
        try container.encode(entityAddress, forKey: .entityAddress)
    }
}

}
