import Common
import CryptoKit
import Dependencies
import EngineToolkit
import Foundation
import Profile

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: BaseURL management
	public var getCurrentBaseURL: GetCurrentBaseURL
	public var setCurrentBaseURL: SetCurrentBaseURL

	// MARK: Request
	public var getGatewayInfo: GetGatewayInfo
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourcesOverview: GetResourcesOverview
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var recentTransactions: GetRecentTransactions
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
	public var transactionDetails: GetTransactionDetails

	public init(
		getCurrentBaseURL: @escaping GetCurrentBaseURL,
		setCurrentBaseURL: @escaping SetCurrentBaseURL,
		getGatewayInfo: @escaping GetGatewayInfo,
		getEpoch: @escaping GetEpoch,
		accountResourcesByAddress: @escaping GetAccountResourcesByAddress,
		resourcesOverview: @escaping GetResourcesOverview,
		resourceDetailsByResourceIdentifier: @escaping GetResourceDetailsByResourceIdentifier,
		recentTransactions: @escaping GetRecentTransactions,
		submitTransaction: @escaping SubmitTransaction,
		transactionStatus: @escaping GetTransactionStatus,
		transactionDetails: @escaping GetTransactionDetails
	) {
		self.getCurrentBaseURL = getCurrentBaseURL
		self.setCurrentBaseURL = setCurrentBaseURL
		self.getGatewayInfo = getGatewayInfo
		self.getEpoch = getEpoch
		self.accountResourcesByAddress = accountResourcesByAddress
		self.resourcesOverview = resourcesOverview
		self.resourceDetailsByResourceIdentifier = resourceDetailsByResourceIdentifier
		self.recentTransactions = recentTransactions
		self.submitTransaction = submitTransaction
		self.transactionStatus = transactionStatus
		self.transactionDetails = transactionDetails
	}
}

public extension GatewayAPIClient {
	typealias GetCurrentBaseURL = @Sendable () async -> URL
	typealias SetCurrentBaseURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?

	typealias GetGatewayInfo = @Sendable () async throws -> GatewayAPI.GatewayInfoResponse
	typealias GetEpoch = @Sendable () async throws -> Epoch

	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityResourcesResponse

	typealias GetResourcesOverview = @Sendable (GatewayAPI.EntityOverviewRequest) async throws -> GatewayAPI.EntityOverviewResponse

	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.EntityDetailsResponse

	typealias GetRecentTransactions = @Sendable (GatewayAPI.RecentTransactionsRequest) async throws -> GatewayAPI.RecentTransactionsResponse

	typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse

	typealias GetTransactionDetails = @Sendable (GatewayAPI.TransactionDetailsRequest) async throws -> GatewayAPI.TransactionDetailsResponse
}
