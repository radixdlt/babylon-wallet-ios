extension CoreAPI {
	/** The transaction execution receipt */
	struct TransactionReceipt: Codable, Hashable {
		private(set) var status: TransactionStatus
		/** Error message (only present if status is `Failed` or `Rejected`) */
		private(set) var errorMessage: String?

		init(status: TransactionStatus, errorMessage: String? = nil) {
			self.status = status
			self.errorMessage = errorMessage
		}

		enum CodingKeys: String, CodingKey, CaseIterable {
			case status
			case errorMessage = "error_message"
		}
	}
}
