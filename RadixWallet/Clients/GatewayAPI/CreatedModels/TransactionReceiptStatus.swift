
@available(*, deprecated, renamed: "GatewayAPI.TransactionReceiptStatus")
public typealias TransactionReceiptStatus = GatewayAPI.TransactionReceiptStatus

// MARK: - GatewayAPI.TransactionReceiptStatus
extension GatewayAPI {
	/** The status of the transaction */
	public enum TransactionReceiptStatus: String, Codable, CaseIterable {
		case succeeded = "CommittedSuccess"
		case failed = "CommittedFailure"
		case rejected = "Rejected"
	}
}
