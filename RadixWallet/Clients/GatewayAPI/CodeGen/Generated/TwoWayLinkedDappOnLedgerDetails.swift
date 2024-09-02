//
// TwoWayLinkedDappOnLedgerDetails.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TwoWayLinkedDappOnLedgerDetails")
public typealias TwoWayLinkedDappOnLedgerDetails = GatewayAPI.TwoWayLinkedDappOnLedgerDetails

extension GatewayAPI {

public struct TwoWayLinkedDappOnLedgerDetails: Codable, Hashable {

    public private(set) var dapps: TwoWayLinkedDappsCollection?
    public private(set) var entities: TwoWayLinkedEntitiesCollection?
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var primaryLocker: String?

    public init(dapps: TwoWayLinkedDappsCollection? = nil, entities: TwoWayLinkedEntitiesCollection? = nil, primaryLocker: String? = nil) {
        self.dapps = dapps
        self.entities = entities
        self.primaryLocker = primaryLocker
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case dapps
        case entities
        case primaryLocker = "primary_locker"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(dapps, forKey: .dapps)
        try container.encodeIfPresent(entities, forKey: .entities)
        try container.encodeIfPresent(primaryLocker, forKey: .primaryLocker)
    }
}

}