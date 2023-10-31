//
// StateKeyValueStoreDataResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateKeyValueStoreDataResponseItem")
public typealias StateKeyValueStoreDataResponseItem = GatewayAPI.StateKeyValueStoreDataResponseItem

extension GatewayAPI {

public struct StateKeyValueStoreDataResponseItem: Codable, Hashable {

    public private(set) var key: ScryptoSborValue
    public private(set) var value: ScryptoSborValue
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64
    public private(set) var isLocked: Bool

    public init(key: ScryptoSborValue, value: ScryptoSborValue, lastUpdatedAtStateVersion: Int64, isLocked: Bool) {
        self.key = key
        self.value = value
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
        self.isLocked = isLocked
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case key
        case value
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
        case isLocked = "is_locked"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
        try container.encode(isLocked, forKey: .isLocked)
    }
}

}
