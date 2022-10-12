//
// EntityDetailsResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct EntityDetailsResponse: Sendable, Codable, Hashable {

    /** The Bech32m-encoded human readable version of the resource's global address */
    public let address: String
    /** TBD */
    public let metadata: [String: String]
    public let details: EntityDetailsResponseDetails

    public init(address: String, metadata: [String: String], details: EntityDetailsResponseDetails) {
        self.address = address
        self.metadata = metadata
        self.details = details
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case address
        case metadata
        case details
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(details, forKey: .details)
    }
}

