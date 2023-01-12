//
// TransactionStatusResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusResponse")
public typealias TransactionStatusResponse = GatewayAPI.TransactionStatusResponse

// MARK: - GatewayAPI.TransactionStatusResponse
public extension GatewayAPI {
	struct TransactionStatusResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		public private(set) var status: TransactionStatus
		public private(set) var knownPayloads: [TransactionStatusResponseKnownPayloadItem]
		public private(set) var errorMessage: String?

		public init(ledgerState: LedgerState, status: TransactionStatus, knownPayloads: [TransactionStatusResponseKnownPayloadItem], errorMessage: String? = nil) {
			self.ledgerState = ledgerState
			self.status = status
			self.knownPayloads = knownPayloads
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case status
			case knownPayloads = "known_payloads"
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(status, forKey: .status)
			try container.encode(knownPayloads, forKey: .knownPayloads)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
