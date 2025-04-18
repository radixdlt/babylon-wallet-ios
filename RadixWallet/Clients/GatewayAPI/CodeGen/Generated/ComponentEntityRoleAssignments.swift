//
// ComponentEntityRoleAssignments.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ComponentEntityRoleAssignments")
typealias ComponentEntityRoleAssignments = GatewayAPI.ComponentEntityRoleAssignments

extension GatewayAPI {

struct ComponentEntityRoleAssignments: Codable, Hashable {

    /** This type is defined in the Core API as `OwnerRole`. See the Core API documentation for more details.  */
    private(set) var owner: AnyCodable
    private(set) var entries: [ComponentEntityRoleAssignmentEntry]

    init(owner: AnyCodable, entries: [ComponentEntityRoleAssignmentEntry]) {
        self.owner = owner
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case owner
        case entries
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(owner, forKey: .owner)
        try container.encode(entries, forKey: .entries)
    }
}

}
