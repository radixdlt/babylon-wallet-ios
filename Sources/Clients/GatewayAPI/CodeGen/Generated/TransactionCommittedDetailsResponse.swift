import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionCommittedDetailsResponse")
public typealias TransactionCommittedDetailsResponse = GatewayAPI.TransactionCommittedDetailsResponse

// MARK: - GatewayAPI.TransactionCommittedDetailsResponse
extension GatewayAPI {
	public struct TransactionCommittedDetailsResponse: Codable, Hashable {
		public private(set) var ledgerState: LedgerState
		public private(set) var transaction: CommittedTransactionInfo
		public private(set) var details: TransactionCommittedDetailsResponseDetails

		public init(ledgerState: LedgerState, transaction: CommittedTransactionInfo, details: TransactionCommittedDetailsResponseDetails) {
			self.ledgerState = ledgerState
			self.transaction = transaction
			self.details = details
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case ledgerState = "ledger_state"
			case transaction
			case details
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ledgerState, forKey: .ledgerState)
			try container.encode(transaction, forKey: .transaction)
			try container.encode(details, forKey: .details)
		}
	}
}
