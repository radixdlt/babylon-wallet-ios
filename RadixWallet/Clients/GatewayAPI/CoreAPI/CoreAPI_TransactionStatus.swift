import Foundation

extension CoreAPI {
	/** The status of the transaction */
	public enum TransactionStatus: String, Codable, CaseIterable {
		case succeeded = "Succeeded"
		case failed = "Failed"
		case rejected = "Rejected"
	}
}
