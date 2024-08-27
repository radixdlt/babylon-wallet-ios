//
// StateNonFungibleDetailsResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleDetailsResponseItem")
public typealias StateNonFungibleDetailsResponseItem = GatewayAPI.StateNonFungibleDetailsResponseItem

extension GatewayAPI {

public struct StateNonFungibleDetailsResponseItem: Codable, Hashable {

    public private(set) var isBurned: Bool
    /** String-encoded non-fungible ID. */
    public private(set) var nonFungibleId: String
    public private(set) var data: ScryptoSborValue?
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64

    public init(isBurned: Bool, nonFungibleId: String, data: ScryptoSborValue? = nil, lastUpdatedAtStateVersion: Int64) {
        self.isBurned = isBurned
        self.nonFungibleId = nonFungibleId
        self.data = data
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case isBurned = "is_burned"
        case nonFungibleId = "non_fungible_id"
        case data
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isBurned, forKey: .isBurned)
        try container.encode(nonFungibleId, forKey: .nonFungibleId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
    }
}

}
