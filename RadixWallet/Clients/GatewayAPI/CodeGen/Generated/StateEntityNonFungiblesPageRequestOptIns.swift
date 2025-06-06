//
// StateEntityNonFungiblesPageRequestOptIns.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityNonFungiblesPageRequestOptIns")
typealias StateEntityNonFungiblesPageRequestOptIns = GatewayAPI.StateEntityNonFungiblesPageRequestOptIns

extension GatewayAPI {

/** Check detailed [OptIns](#section/Using-endpoints-with-opt-in-features) documentation for more details */
struct StateEntityNonFungiblesPageRequestOptIns: Codable, Hashable {

    /** if set to `true`, first page of non fungible ids are returned for each non fungible resource, with cursor which can be later used at `/state/entity/page/non-fungible-vault/ids` endpoint. */
    private(set) var nonFungibleIncludeNfids: Bool? = false
    /** allows specifying explicitly metadata properties which should be returned in response, limited to max 20 items. */
    private(set) var explicitMetadata: [String]?

    init(nonFungibleIncludeNfids: Bool? = false, explicitMetadata: [String]? = nil) {
        self.nonFungibleIncludeNfids = nonFungibleIncludeNfids
        self.explicitMetadata = explicitMetadata
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case nonFungibleIncludeNfids = "non_fungible_include_nfids"
        case explicitMetadata = "explicit_metadata"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(nonFungibleIncludeNfids, forKey: .nonFungibleIncludeNfids)
        try container.encodeIfPresent(explicitMetadata, forKey: .explicitMetadata)
    }
}

}
