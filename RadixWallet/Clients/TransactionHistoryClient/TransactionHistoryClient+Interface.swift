import Foundation

// MARK: - TransactionHistoryClient
public struct TransactionHistoryClient: Sendable, DependencyKey {
	public var getTransactionHistory: GetTransactionHistory
}

// MARK: TransactionHistoryClient.GetTransactionHistory
extension TransactionHistoryClient {
	public typealias GetTransactionHistory = @Sendable (TransactionHistoryRequest) async throws -> TransactionHistoryResponse
}

// MARK: - TransactionHistoryRequest
public struct TransactionHistoryRequest: Sendable, Hashable {
	public let account: AccountAddress
	public let period: Range<Date>
	public let filters: [TransactionFilter]
	public let allResources: Set<ResourceAddress>
	public let ascending: Bool
	public let cursor: String?
}

// MARK: - TransactionHistoryResponse
public struct TransactionHistoryResponse: Sendable, Hashable {
	public let cursor: String?
	public let allResources: IdentifiedArrayOf<OnLedgerEntity.Resource>
	public let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem
public struct TransactionHistoryItem: Sendable, Hashable {
	let time: Date
	let message: String?
	let manifestClass: GatewayAPI.ManifestClass?
	let withdrawals: [ResourceBalance]
	let deposits: [ResourceBalance]
	let depositSettingsUpdated: Bool
}

// MARK: - TransactionFilter
public enum TransactionFilter: Hashable, Sendable {
	case transferType(TransferType)
	case asset(ResourceAddress)
	case transactionType(TransactionType)

	public enum TransferType: CaseIterable, Sendable {
		case withdrawal
		case deposit
	}

	public typealias TransactionType = GatewayAPI.ManifestClass

	public var transferType: TransferType? {
		guard case let .transferType(transferType) = self else { return nil }
		return transferType
	}

	public var asset: ResourceAddress? {
		guard case let .asset(asset) = self else { return nil }
		return asset
	}

	public var transactionType: TransactionType? {
		guard case let .transactionType(transactionType) = self else { return nil }
		return transactionType
	}
}

// extension TransactionHistoryClient {
//	@Sendable
//	func getTransactionHistory(
//		account: AccountAddress,
//		allResourceAddresses: Set<ResourceAddress>,
//		period: Range<Date>,
//		filters: [TransactionFilter],
//		ascending: Bool,
//		cursor: String?
//	) async throws -> TransactionHistoryResponse {
//		getTransactionHistory(
//			.init(
//				account: <#T##AccountAddress#>,
//				period: <#T##Range<Date>#>,
//				filters: <#T##[TransactionFilter]#>,
//				allResources: <#T##Set<ResourceAddress>#>,
//				ascending: <#T##Bool#>,
//				cursor: <#T##String?#>
//			)
//		)
//	}
// }
