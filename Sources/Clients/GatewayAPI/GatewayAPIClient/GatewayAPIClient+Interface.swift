import Common
import CryptoKit
import Dependencies
import Foundation
import Profile

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: DependencyKey {
	// MARK: BaseURL management
	public var getCurrentBaseURL: GetCurrentBaseURL
	public var setCurrentBaseURL: SetCurrentBaseURL

	// MARK: Request
	public var getGateway: GetGateway
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
		getGateway: @escaping GetGateway,
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
		self.getGateway = getGateway
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
	typealias GetCurrentBaseURL = @Sendable () -> URL
	typealias SetCurrentBaseURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?

	typealias GetGateway = @Sendable () async throws -> GatewayInfoResponse

	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> EntityResourcesResponse
	typealias GetResourcesOverview = @Sendable (EntityOverviewRequest) async throws -> EntityOverviewResponse
	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> EntityDetailsResponse

	typealias GetRecentTransactions = @Sendable (RecentTransactionsRequest) async throws -> RecentTransactionsResponse
	typealias SubmitTransaction = @Sendable (TransactionSubmitRequest) async throws -> TransactionSubmitResponse
	typealias GetTransactionStatus = @Sendable (TransactionStatusRequest) async throws -> TransactionStatusResponse
	typealias GetTransactionDetails = @Sendable (TransactionDetailsRequest) async throws -> TransactionDetailsResponse
}
