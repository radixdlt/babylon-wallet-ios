import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionSubmitResponse")
public typealias TransactionSubmitResponse = GatewayAPI.TransactionSubmitResponse

// MARK: - GatewayAPI.TransactionSubmitResponse
extension GatewayAPI {
	public struct TransactionSubmitResponse: Codable, Hashable {
		/** Is true if the transaction is a duplicate of an existing pending transaction. */
		public private(set) var duplicate: Bool

		public init(duplicate: Bool) {
			self.duplicate = duplicate
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case duplicate
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(duplicate, forKey: .duplicate)
		}
	}
}
