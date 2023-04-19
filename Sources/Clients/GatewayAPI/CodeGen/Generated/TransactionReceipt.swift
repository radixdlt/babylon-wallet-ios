import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionReceipt")
public typealias TransactionReceipt = GatewayAPI.TransactionReceipt

// MARK: - GatewayAPI.TransactionReceipt
extension GatewayAPI {
	/** The transaction execution receipt */
	public struct TransactionReceipt: Codable, Hashable {
		public private(set) var status: TransactionReceiptStatus
		/** The manifest line-by-line engine return data (only present if `status` is `Succeeded`) */
		public private(set) var output: [SborData]?
		/** Error message (only present if status is `Failed` or `Rejected`) */
		public private(set) var errorMessage: String?

		public init(status: TransactionReceiptStatus, output: [SborData]? = nil, errorMessage: String? = nil) {
			self.status = status
			self.output = output
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case status
			case output
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(status, forKey: .status)
			try container.encodeIfPresent(output, forKey: .output)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
