import Foundation

// MARK: - TransactionHistoryClient
public struct TransactionHistoryClient: Sendable, DependencyKey {
	public var getTransactionHistory: GetTransactionHistory
}

// MARK: TransactionHistoryClient.GetTransactionHistory
extension TransactionHistoryClient {
	public typealias GetTransactionHistory = @Sendable (_ account: AccountAddress, _ cursor: String?) async throws -> TransactionHistoryResponse
}

// MARK: - TransactionHistoryResponse
public struct TransactionHistoryResponse: Sendable, Hashable {
	public let cursor: String?
	public let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem
public struct TransactionHistoryItem: Sendable, Hashable {
	let time: Date
	let message: String?
	let actions: [Action]
	let manifestClass: GatewayAPI.ManifestClass

	enum Action: Sendable, Hashable {
		case deposit(ResourceBalance)
		case withdrawal(ResourceBalance)
		case otherBalanceChange(ResourceBalance.Fungible, GatewayAPI.TransactionFungibleFeeBalanceChangeType)
		case settings
	}
}
