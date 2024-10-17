
@available(*, deprecated, renamed: "GatewayAPI.TransactionReceiptStatus")
typealias TransactionReceiptStatus = GatewayAPI.TransactionReceiptStatus

// MARK: - GatewayAPI.TransactionReceiptStatus
extension GatewayAPI {
	/** The status of the transaction */
	enum TransactionReceiptStatus: String, Codable, CaseIterable {
		case succeeded = "CommittedSuccess"
		case failed = "CommittedFailure"
		case rejected = "Rejected"
	}
}
