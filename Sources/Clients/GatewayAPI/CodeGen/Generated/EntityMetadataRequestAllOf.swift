//
// EntityMetadataRequestAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataRequestAllOf")
public typealias EntityMetadataRequestAllOf = GatewayAPI.EntityMetadataRequestAllOf

// MARK: - GatewayAPI.EntityMetadataRequestAllOf
extension GatewayAPI {
	public struct EntityMetadataRequestAllOf: Codable, Hashable {
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limit: Int?

		public init(address: String, cursor: String? = nil, limit: Int? = nil) {
			self.address = address
			self.cursor = cursor
			self.limit = limit
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case address
			case cursor
			case limit
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(address, forKey: .address)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limit, forKey: .limit)
		}
	}
}
