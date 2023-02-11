//
// NonFungibleDataRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.NonFungibleDataRequest")
public typealias NonFungibleDataRequest = GatewayAPI.NonFungibleDataRequest

// MARK: - GatewayAPI.NonFungibleDataRequest
extension GatewayAPI {
	public struct NonFungibleDataRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		public private(set) var nonFungibleLocalId: String
		/** This cursor allows forward pagination, by providing the cursor from the previous request. */
		public private(set) var cursor: String?
		/** The page size requested. */
		public private(set) var limit: Int?

		public init(atLedgerState: LedgerStateSelector? = nil, address: String, nonFungibleLocalId: String, cursor: String? = nil, limit: Int? = nil) {
			self.atLedgerState = atLedgerState
			self.address = address
			self.nonFungibleLocalId = nonFungibleLocalId
			self.cursor = cursor
			self.limit = limit
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case address
			case nonFungibleLocalId = "non_fungible_id"
			case cursor
			case limit
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encode(address, forKey: .address)
			try container.encode(nonFungibleLocalId, forKey: .nonFungibleLocalId)
			try container.encodeIfPresent(cursor, forKey: .cursor)
			try container.encodeIfPresent(limit, forKey: .limit)
		}
	}
}
