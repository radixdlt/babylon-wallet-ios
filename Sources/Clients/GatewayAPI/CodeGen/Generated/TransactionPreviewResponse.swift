import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewResponse")
public typealias TransactionPreviewResponse = GatewayAPI.TransactionPreviewResponse

// MARK: - GatewayAPI.TransactionPreviewResponse
extension GatewayAPI {
	public struct TransactionPreviewResponse: Codable, Hashable {
		/** The hex-sbor-encoded receipt */
		public private(set) var encodedReceipt: String
		public private(set) var receipt: TransactionReceipt
		public private(set) var resourceChanges: [AnyCodable]
		public private(set) var logs: [TransactionPreviewResponseLogsInner]

		public init(encodedReceipt: String, receipt: TransactionReceipt, resourceChanges: [AnyCodable], logs: [TransactionPreviewResponseLogsInner]) {
			self.encodedReceipt = encodedReceipt
			self.receipt = receipt
			self.resourceChanges = resourceChanges
			self.logs = logs
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case encodedReceipt = "encoded_receipt"
			case receipt
			case resourceChanges = "resource_changes"
			case logs
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(encodedReceipt, forKey: .encodedReceipt)
			try container.encode(receipt, forKey: .receipt)
			try container.encode(resourceChanges, forKey: .resourceChanges)
			try container.encode(logs, forKey: .logs)
		}
	}
}
