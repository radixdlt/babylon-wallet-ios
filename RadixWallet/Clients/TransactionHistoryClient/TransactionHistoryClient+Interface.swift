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
	public let parameters: Parameters
	public let cursor: String?

	public let allResourcesAddresses: Set<ResourceAddress>
	public let resources: IdentifiedArrayOf<OnLedgerEntity.Resource>

	// MARK: - Parameters
	public struct Parameters: Sendable, Hashable {
		public let period: Range<Date>
		public let filters: [TransactionFilter]
		public let direction: TransactionHistory.Direction
	}
}

// MARK: - TransactionHistoryResponse
public struct TransactionHistoryResponse: Sendable, Hashable {
	public let nextCursor: String?
	public let resources: IdentifiedArrayOf<OnLedgerEntity.Resource>
	public let items: [TransactionHistoryItem]
}

// MARK: - TransactionHistoryItem
public struct TransactionHistoryItem: Sendable, Hashable, Identifiable {
	public let id: TXID
	public let time: Date
	public let message: String?
	public let manifestClass: GatewayAPI.ManifestClass?
	public let withdrawals: [ResourceBalance]
	public let deposits: [ResourceBalance]
	public let depositSettingsUpdated: Bool
	public let failed: Bool

	init(
		id: TXID,
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
