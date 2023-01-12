//
// EntityMetadataResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataResponse")
public typealias EntityMetadataResponse = GatewayAPI.EntityMetadataResponse

// MARK: - GatewayAPI.EntityMetadataResponse
public extension GatewayAPI {
	struct EntityMetadataResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		public private(set) var metadata: EntityMetadataCollection

		public init(ledgerState: LedgerState, address: String, metadata: EntityMetadataCollection) {
			self.ledgerState = ledgerState
			self.address = address
			self.metadata = metadata
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case address
			case metadata
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(address, forKey: .address)
			try container.encode(metadata, forKey: .metadata)
		}
	}
}
