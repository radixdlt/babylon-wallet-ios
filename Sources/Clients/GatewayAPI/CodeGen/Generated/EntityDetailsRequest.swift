//
// EntityDetailsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityDetailsRequest")
public typealias EntityDetailsRequest = GatewayAPI.EntityDetailsRequest

// MARK: - GatewayAPI.EntityDetailsRequest
extension GatewayAPI {
	public struct EntityDetailsRequest: Codable, Hashable {
		public private(set) var atLedgerState: LedgerStateSelector?
		/** The Bech32m-encoded human readable version of the entity's global address. */
		public private(set) var address: String

		public init(atLedgerState: LedgerStateSelector? = nil, address: String) {
			self.atLedgerState = atLedgerState
			self.address = address
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case atLedgerState = "at_ledger_state"
			case address
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
			try container.encode(address, forKey: .address)
		}
	}
}
