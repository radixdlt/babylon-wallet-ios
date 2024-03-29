//
// RoleKey.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.RoleKey")
public typealias RoleKey = GatewayAPI.RoleKey

extension GatewayAPI {

public struct RoleKey: Codable, Hashable {

    public private(set) var name: String
    public private(set) var module: ObjectModuleId

    public init(name: String, module: ObjectModuleId) {
        self.name = name
        self.module = module
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case module
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(module, forKey: .module)
    }
}

}
