//
// ValidatorUptimeCollectionItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorUptimeCollectionItem")
public typealias ValidatorUptimeCollectionItem = GatewayAPI.ValidatorUptimeCollectionItem

extension GatewayAPI {

public struct ValidatorUptimeCollectionItem: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var address: String
    /** number of proposals made. */
    public private(set) var proposalsMade: Int64?
    /** number of proposals missed. */
    public private(set) var proposalsMissed: Int64?
    /** number of epochs validator was active in. */
    public private(set) var epochsActiveIn: Int64

    public init(address: String, proposalsMade: Int64? = nil, proposalsMissed: Int64? = nil, epochsActiveIn: Int64) {
        self.address = address
        self.proposalsMade = proposalsMade
        self.proposalsMissed = proposalsMissed
        self.epochsActiveIn = epochsActiveIn
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case address
        case proposalsMade = "proposals_made"
        case proposalsMissed = "proposals_missed"
        case epochsActiveIn = "epochs_active_in"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(proposalsMade, forKey: .proposalsMade)
        try container.encodeIfPresent(proposalsMissed, forKey: .proposalsMissed)
        try container.encode(epochsActiveIn, forKey: .epochsActiveIn)
    }
}

}
