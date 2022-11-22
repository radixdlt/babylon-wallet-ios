//
// EntityResourcesResponseNonFungibleResourcesItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityResourcesResponseNonFungibleResourcesItem")
public typealias EntityResourcesResponseNonFungibleResourcesItem = GatewayAPI.EntityResourcesResponseNonFungibleResourcesItem

// MARK: - GatewayAPI.EntityResourcesResponseNonFungibleResourcesItem
public extension GatewayAPI {
	struct EntityResourcesResponseNonFungibleResourcesItem: Codable, Hashable {
		/** The Bech32m-encoded human readable version of the resource (fungible, non-fungible) global address. */
		public private(set) var address: String
		public private(set) var amount: Double

		public init(address: String, amount: Double) {
			self.address = address
			self.amount = amount
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case amount
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encode(amount, forKey: .amount)
		}
	}
}
