//
// EntityFungiblesResponseAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityFungiblesResponseAllOf")
public typealias EntityFungiblesResponseAllOf = GatewayAPI.EntityFungiblesResponseAllOf

// MARK: - GatewayAPI.EntityFungiblesResponseAllOf
extension GatewayAPI {
	public struct EntityFungiblesResponseAllOf: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		public private(set) var fungibles: FungibleResourcesCollection

		public init(address: String, fungibles: FungibleResourcesCollection) {
			self.address = address
			self.fungibles = fungibles
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case fungibles
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encode(fungibles, forKey: .fungibles)
		}
	}
}
