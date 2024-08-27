//
// NonFungibleResourcesCollectionItemVaultAggregatedVaultItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem")
public typealias NonFungibleResourcesCollectionItemVaultAggregatedVaultItem = GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregatedVaultItem

extension GatewayAPI {

public struct NonFungibleResourcesCollectionItemVaultAggregatedVaultItem: Codable, Hashable {

    public private(set) var totalCount: Int64
    /** If specified, contains a cursor to query next page of the `items` collection. */
    public private(set) var nextCursor: String?
    public private(set) var items: [String]?
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var vaultAddress: String
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64

    public init(totalCount: Int64, nextCursor: String? = nil, items: [String]? = nil, vaultAddress: String, lastUpdatedAtStateVersion: Int64) {
        self.totalCount = totalCount
        self.nextCursor = nextCursor
        self.items = items
        self.vaultAddress = vaultAddress
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case totalCount = "total_count"
        case nextCursor = "next_cursor"
        case items
        case vaultAddress = "vault_address"
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalCount, forKey: .totalCount)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encode(vaultAddress, forKey: .vaultAddress)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
    }
}

}
