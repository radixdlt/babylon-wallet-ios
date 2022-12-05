//
// NonFungibleIdsResponseAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleIdsResponseAllOf")
public typealias NonFungibleIdsResponseAllOf = GatewayAPI.NonFungibleIdsResponseAllOf

// MARK: - GatewayAPI.NonFungibleIdsResponseAllOf
public extension GatewayAPI {
	struct NonFungibleIdsResponseAllOf: Codable, Hashable {
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		public private(set) var nonFungibleIds: NonFungibleIdsCollection

		public init(address: String, nonFungibleIds: NonFungibleIdsCollection) {
			self.address = address
			self.nonFungibleIds = nonFungibleIds
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case nonFungibleIds = "non_fungible_ids"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encode(nonFungibleIds, forKey: .nonFungibleIds)
		}
	}
}
