//
// AccountLockerVaultCollectionItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.AccountLockerVaultCollectionItem")
public typealias AccountLockerVaultCollectionItem = GatewayAPI.AccountLockerVaultCollectionItem

extension GatewayAPI {

public struct AccountLockerVaultCollectionItem: Codable, Hashable {

    public private(set) var type: AccountLockerVaultCollectionItemType
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var resourceAddress: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var vaultAddress: String
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64

    public init(type: AccountLockerVaultCollectionItemType, resourceAddress: String, vaultAddress: String, lastUpdatedAtStateVersion: Int64) {
        self.type = type
        self.resourceAddress = resourceAddress
        self.vaultAddress = vaultAddress
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case resourceAddress = "resource_address"
        case vaultAddress = "vault_address"
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(resourceAddress, forKey: .resourceAddress)
        try container.encode(vaultAddress, forKey: .vaultAddress)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
    }
}

}
