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
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
	public var getCommittedTransaction: GetCommittedTransaction

	public init(
		getCurrentBaseURL: @escaping GetCurrentBaseURL,
		setCurrentBaseURL: @escaping SetCurrentBaseURL,
		getEpoch: @escaping GetEpoch,
		accountResourcesByAddress: @escaping GetAccountResourcesByAddress,
		resourceDetailsByResourceIdentifier: @escaping GetResourceDetailsByResourceIdentifier,
		submitTransaction: @escaping SubmitTransaction,
		transactionStatus: @escaping GetTransactionStatus,
		getCommittedTransaction: @escaping GetCommittedTransaction
	) {
		self.getCurrentBaseURL = getCurrentBaseURL
		self.setCurrentBaseURL = setCurrentBaseURL
		self.getEpoch = getEpoch
		self.accountResourcesByAddress = accountResourcesByAddress
		self.resourceDetailsByResourceIdentifier = resourceDetailsByResourceIdentifier
		self.submitTransaction = submitTransaction
		self.transactionStatus = transactionStatus
		self.getCommittedTransaction = getCommittedTransaction
	}
}

public extension GatewayAPIClient {
	typealias GetCurrentBaseURL = @Sendable () async -> URL
	typealias SetCurrentBaseURL = @Sendable (URL) async throws -> AppPreferences.NetworkAndGateway?

	typealias GetEpoch = @Sendable () async throws -> V0StateEpochResponse
	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> V0StateComponentResponse
	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> V0StateResourceResponse
	typealias SubmitTransaction = @Sendable (V0TransactionSubmitRequest) async throws -> V0TransactionSubmitResponse
	typealias GetTransactionStatus = @Sendable (V0TransactionStatusRequest) async throws -> V0TransactionStatusResponse
	typealias GetCommittedTransaction = @Sendable (V0CommittedTransactionRequest) async throws -> V0CommittedTransactionResponse
}
