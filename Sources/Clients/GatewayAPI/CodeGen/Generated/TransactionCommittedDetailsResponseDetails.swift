import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionCommittedDetailsResponseDetails")
public typealias TransactionCommittedDetailsResponseDetails = GatewayAPI.TransactionCommittedDetailsResponseDetails

// MARK: - GatewayAPI.TransactionCommittedDetailsResponseDetails
extension GatewayAPI {
	public struct TransactionCommittedDetailsResponseDetails: Codable, Hashable {
		/** Hex-encoded binary blob. */
		public private(set) var rawHex: String
		public private(set) var receipt: AnyCodable
		public private(set) var referencedGlobalEntities: [String]
		/** Hex-encoded binary blob. */
		public private(set) var messageHex: String?

		public init(rawHex: String, receipt: AnyCodable, referencedGlobalEntities: [String], messageHex: String? = nil) {
			self.rawHex = rawHex
			self.receipt = receipt
			self.referencedGlobalEntities = referencedGlobalEntities
			self.messageHex = messageHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case rawHex = "raw_hex"
			case receipt
			case referencedGlobalEntities = "referenced_global_entities"
			case messageHex = "message_hex"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(rawHex, forKey: .rawHex)
			try container.encode(receipt, forKey: .receipt)
			try container.encode(referencedGlobalEntities, forKey: .referencedGlobalEntities)
			try container.encodeIfPresent(messageHex, forKey: .messageHex)
		}
	}
}
