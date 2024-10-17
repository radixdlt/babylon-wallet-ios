import Foundation

// MARK: - TransactionHistoryClient
struct TransactionHistoryClient: Sendable, DependencyKey {
	var getFirstTransactionDate: GetFirstTransactionDate
	var getTransactionHistory: GetTransactionHistory
}

// MARK: TransactionHistoryClient.GetTransactionHistory
extension TransactionHistoryClient {
	typealias GetFirstTransactionDate = @Sendable (AccountAddress) async throws -> Date?
	typealias GetTransactionHistory = @Sendable (TransactionHistoryRequest) async throws -> TransactionHistoryResponse
}

// MARK: - TransactionHistoryRequest
struct TransactionHistoryRequest: Sendable, Hashable {
	let account: AccountAddress
	let parameters: Parameters
	let cursor: String?

	let allResourcesAddresses: Set<ResourceAddress>
	let resources: IdentifiedArrayOf<OnLedgerEntity.Resource>

	// MARK: - Parameters
	struct Parameters: Sendable, Hashable {
		let period: AnyRange<Date>
		let filters: [TransactionFilter]
		let direction: TransactionHistory.Direction
	}
}

// MARK: - TransactionHistoryResponse
struct TransactionHistoryResponse: Sendable, Hashable {
	let nextCursor: String?
	let resources: IdentifiedArrayOf<OnLedgerEntity.Resource>
	let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem
struct TransactionHistoryItem: Sendable, Hashable, Identifiable {
	let id: IntentHash
	let time: Date
	let message: String?
	let manifestClass: GatewayAPI.ManifestClass?
	let withdrawals: [ResourceBalance]
	let deposits: [ResourceBalance]
	let depositSettingsUpdated: Bool
	let failed: Bool

	init(
		id: IntentHash,
		time: Date,
		message: String? = nil,
		manifestClass: GatewayAPI.ManifestClass? = nil,
		withdrawals: [ResourceBalance] = [],
		deposits: [ResourceBalance] = [],
		depositSettingsUpdated: Bool = false,
		failed: Bool = false
	) {
		self.id = id
		self.time = time
		self.message = message
		self.manifestClass = manifestClass
		self.withdrawals = withdrawals
		self.deposits = deposits
		self.depositSettingsUpdated = depositSettingsUpdated
		self.failed = failed
	}
}

// MARK: - TransactionFilter
enum TransactionFilter: Hashable, Sendable {
	case transferType(TransferType)
	case asset(ResourceAddress)
	case transactionType(TransactionType)

	enum TransferType: CaseIterable, Sendable {
		case deposit
		case withdrawal
	}

	typealias TransactionType = GatewayAPI.ManifestClass

	var transferType: TransferType? {
		guard case let .transferType(transferType) = self else { return nil }
		return transferType
	}

	var asset: ResourceAddress? {
		guard case let .asset(asset) = self else { return nil }
		return asset
	}

	var transactionType: TransactionType? {
		guard case let .transactionType(transactionType) = self else { return nil }
		return transactionType
	}
}
