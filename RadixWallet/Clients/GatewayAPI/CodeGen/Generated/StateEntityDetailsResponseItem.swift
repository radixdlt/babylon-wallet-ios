//
// StateEntityDetailsResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseItem")
typealias StateEntityDetailsResponseItem = GatewayAPI.StateEntityDetailsResponseItem

extension GatewayAPI {

struct StateEntityDetailsResponseItem: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    private(set) var address: String
    private(set) var fungibleResources: FungibleResourcesCollection?
    private(set) var nonFungibleResources: NonFungibleResourcesCollection?
    private(set) var ancestorIdentities: StateEntityDetailsResponseItemAncestorIdentities?
    private(set) var metadata: EntityMetadataCollection
    private(set) var explicitMetadata: EntityMetadataCollection?
    private(set) var details: StateEntityDetailsResponseItemDetails?

    init(address: String, fungibleResources: FungibleResourcesCollection? = nil, nonFungibleResources: NonFungibleResourcesCollection? = nil, ancestorIdentities: StateEntityDetailsResponseItemAncestorIdentities? = nil, metadata: EntityMetadataCollection, explicitMetadata: EntityMetadataCollection? = nil, details: StateEntityDetailsResponseItemDetails? = nil) {
        self.address = address
        self.fungibleResources = fungibleResources
        self.nonFungibleResources = nonFungibleResources
        self.ancestorIdentities = ancestorIdentities
        self.metadata = metadata
        self.explicitMetadata = explicitMetadata
        self.details = details
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case address
        case fungibleResources = "fungible_resources"
        case nonFungibleResources = "non_fungible_resources"
        case ancestorIdentities = "ancestor_identities"
        case metadata
        case explicitMetadata = "explicit_metadata"
        case details
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(fungibleResources, forKey: .fungibleResources)
        try container.encodeIfPresent(nonFungibleResources, forKey: .nonFungibleResources)
        try container.encodeIfPresent(ancestorIdentities, forKey: .ancestorIdentities)
        try container.encode(metadata, forKey: .metadata)
        try container.encodeIfPresent(explicitMetadata, forKey: .explicitMetadata)
        try container.encodeIfPresent(details, forKey: .details)
    }
}

}
