//
// StateEntityDetailsResponseItemAncestorIdentities.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseItemAncestorIdentities")
public typealias StateEntityDetailsResponseItemAncestorIdentities = GatewayAPI.StateEntityDetailsResponseItemAncestorIdentities

// MARK: - GatewayAPI.StateEntityDetailsResponseItemAncestorIdentities
extension GatewayAPI {
	public struct StateEntityDetailsResponseItemAncestorIdentities: Codable, Hashable {
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var parentAddress: String?
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var ownerAddress: String?
		/** Bech32m-encoded human readable version of the entity's global address or hex-encoded id. */
		public private(set) var globalAddress: String?

		public init(parentAddress: String? = nil, ownerAddress: String? = nil, globalAddress: String? = nil) {
			self.parentAddress = parentAddress
			self.ownerAddress = ownerAddress
			self.globalAddress = globalAddress
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case parentAddress = "parent_address"
			case ownerAddress = "owner_address"
			case globalAddress = "global_address"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(parentAddress, forKey: .parentAddress)
			try container.encodeIfPresent(ownerAddress, forKey: .ownerAddress)
			try container.encodeIfPresent(globalAddress, forKey: .globalAddress)
		}
	}
}
