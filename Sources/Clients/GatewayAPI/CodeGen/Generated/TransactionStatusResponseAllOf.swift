import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatusResponseAllOf")
public typealias TransactionStatusResponseAllOf = GatewayAPI.TransactionStatusResponseAllOf

// MARK: - GatewayAPI.TransactionStatusResponseAllOf
extension GatewayAPI {
	public struct TransactionStatusResponseAllOf: Codable, Hashable {
		public private(set) var status: TransactionStatus
		public private(set) var knownPayloads: [TransactionStatusResponseKnownPayloadItem]
		public private(set) var errorMessage: String?

		public init(status: TransactionStatus, knownPayloads: [TransactionStatusResponseKnownPayloadItem], errorMessage: String? = nil) {
			self.status = status
			self.knownPayloads = knownPayloads
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case status
			case knownPayloads = "known_payloads"
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(status, forKey: .status)
			try container.encode(knownPayloads, forKey: .knownPayloads)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
