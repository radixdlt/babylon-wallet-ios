//
// EntityNonFungiblesResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityNonFungiblesResponse")
public typealias EntityNonFungiblesResponse = GatewayAPI.EntityNonFungiblesResponse

// MARK: - GatewayAPI.EntityNonFungiblesResponse
extension GatewayAPI {
	public struct EntityNonFungiblesResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String
		public private(set) var nonFungibles: NonFungibleResourcesCollection

		public init(ledgerState: LedgerState, address: String, nonFungibles: NonFungibleResourcesCollection) {
			self.ledgerState = ledgerState
			self.address = address
			self.nonFungibles = nonFungibles
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case address
			case nonFungibles = "non_fungibles"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(address, forKey: .address)
			try container.encode(nonFungibles, forKey: .nonFungibles)
		}
	}
}
