import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionStatus")
public typealias TransactionStatus = GatewayAPI.TransactionStatus

// MARK: - GatewayAPI.TransactionStatus
extension GatewayAPI {
	public enum TransactionStatus: String, Codable, CaseIterable {
		case unknown = "Unknown"
		case committedSuccess = "CommittedSuccess"
		case committedFailure = "CommittedFailure"
		case pending = "Pending"
		case rejected = "Rejected"
	}
}
