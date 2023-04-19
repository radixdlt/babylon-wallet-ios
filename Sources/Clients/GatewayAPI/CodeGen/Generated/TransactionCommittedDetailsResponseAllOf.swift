import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionCommittedDetailsResponseAllOf")
public typealias TransactionCommittedDetailsResponseAllOf = GatewayAPI.TransactionCommittedDetailsResponseAllOf

// MARK: - GatewayAPI.TransactionCommittedDetailsResponseAllOf
extension GatewayAPI {
	public struct TransactionCommittedDetailsResponseAllOf: Codable, Hashable {
		public private(set) var transaction: CommittedTransactionInfo
		public private(set) var details: TransactionCommittedDetailsResponseDetails

		public init(transaction: CommittedTransactionInfo, details: TransactionCommittedDetailsResponseDetails) {
			self.transaction = transaction
			self.details = details
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case transaction
			case details
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(transaction, forKey: .transaction)
			try container.encode(details, forKey: .details)
		}
	}
}
