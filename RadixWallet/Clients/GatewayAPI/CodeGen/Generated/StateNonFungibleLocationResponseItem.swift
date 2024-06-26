//
// StateNonFungibleLocationResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleLocationResponseItem")
public typealias StateNonFungibleLocationResponseItem = GatewayAPI.StateNonFungibleLocationResponseItem

extension GatewayAPI {

public struct StateNonFungibleLocationResponseItem: Codable, Hashable {

    /** String-encoded non-fungible ID. */
    public private(set) var nonFungibleId: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var owningVaultAddress: String?
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var owningVaultParentAncestorAddress: String?
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var owningVaultGlobalAncestorAddress: String?
    public private(set) var isBurned: Bool
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastUpdatedAtStateVersion: Int64

    public init(nonFungibleId: String, owningVaultAddress: String? = nil, owningVaultParentAncestorAddress: String? = nil, owningVaultGlobalAncestorAddress: String? = nil, isBurned: Bool, lastUpdatedAtStateVersion: Int64) {
        self.nonFungibleId = nonFungibleId
        self.owningVaultAddress = owningVaultAddress
        self.owningVaultParentAncestorAddress = owningVaultParentAncestorAddress
        self.owningVaultGlobalAncestorAddress = owningVaultGlobalAncestorAddress
        self.isBurned = isBurned
        self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case nonFungibleId = "non_fungible_id"
        case owningVaultAddress = "owning_vault_address"
        case owningVaultParentAncestorAddress = "owning_vault_parent_ancestor_address"
        case owningVaultGlobalAncestorAddress = "owning_vault_global_ancestor_address"
        case isBurned = "is_burned"
        case lastUpdatedAtStateVersion = "last_updated_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nonFungibleId, forKey: .nonFungibleId)
        try container.encodeIfPresent(owningVaultAddress, forKey: .owningVaultAddress)
        try container.encodeIfPresent(owningVaultParentAncestorAddress, forKey: .owningVaultParentAncestorAddress)
        try container.encodeIfPresent(owningVaultGlobalAncestorAddress, forKey: .owningVaultGlobalAncestorAddress)
        try container.encode(isBurned, forKey: .isBurned)
        try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
    }
}

}
