//
// StateKeyValueStoreDataRequestAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateKeyValueStoreDataRequestAllOf")
public typealias StateKeyValueStoreDataRequestAllOf = GatewayAPI.StateKeyValueStoreDataRequestAllOf

extension GatewayAPI {

public struct StateKeyValueStoreDataRequestAllOf: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var keyValueStoreAddress: String
    public private(set) var keys: [StateKeyValueStoreDataRequestKeyItem]

    public init(keyValueStoreAddress: String, keys: [StateKeyValueStoreDataRequestKeyItem]) {
        self.keyValueStoreAddress = keyValueStoreAddress
        self.keys = keys
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case keyValueStoreAddress = "key_value_store_address"
        case keys
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyValueStoreAddress, forKey: .keyValueStoreAddress)
        try container.encode(keys, forKey: .keys)
    }
}

}
