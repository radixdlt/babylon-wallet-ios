import Foundation

public enum CoreAPI {
	// NB: This is used by TransactionPreviewResponse.receipt
	public struct TransactionReceipt: Codable, Hashable {
		public private(set) var status: GatewayAPI.TransactionReceiptStatus?
		public private(set) var errorMessage: String?

		init(status: GatewayAPI.TransactionReceiptStatus? = nil, errorMessage: String? = nil) {
			self.status = status
			self.errorMessage = errorMessage
		}
	}
}
