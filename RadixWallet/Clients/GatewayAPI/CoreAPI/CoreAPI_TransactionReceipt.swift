extension CoreAPI {
	/** The transaction execution receipt */
	public struct TransactionReceipt: Codable, Hashable {
		public private(set) var status: TransactionStatus
		/** Error message (only present if status is `Failed` or `Rejected`) */
		public private(set) var errorMessage: String?

		public init(status: TransactionStatus, errorMessage: String? = nil) {
			self.status = status
			self.errorMessage = errorMessage
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case status
			case errorMessage = "error_message"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(status, forKey: .status)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}
}
