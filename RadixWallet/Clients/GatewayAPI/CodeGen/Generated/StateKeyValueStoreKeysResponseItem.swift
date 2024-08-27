//
// StateKeyValueStoreKeysResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateKeyValueStoreKeysResponseItem")
public typealias StateKeyValueStoreKeysResponseItem = GatewayAPI.StateKeyValueStoreKeysResponseItem

extension GatewayAPI {

public struct StateKeyValueStoreKeysResponseItem: Codable, Hashable {

    public private(set) var key: ScryptoSborValue
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64

    public init(key: ScryptoSborValue, lastUpdatedAtStateVersion: Int64) {
        self.key = key
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case key
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
    }
}

}
