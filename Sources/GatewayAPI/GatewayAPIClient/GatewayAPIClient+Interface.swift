import Common
import CryptoKit
import Foundation
import Profile

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient {
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus

	public init(
		accountResourcesByAddress: @escaping GetAccountResourcesByAddress,
		resourceDetailsByResourceIdentifier: @escaping GetResourceDetailsByResourceIdentifier,
		submitTransaction: @escaping SubmitTransaction,
		transactionStatus: @escaping GetTransactionStatus
	) {
		self.accountResourcesByAddress = accountResourcesByAddress
		self.resourceDetailsByResourceIdentifier = resourceDetailsByResourceIdentifier
		self.submitTransaction = submitTransaction
		self.transactionStatus = transactionStatus
	}
}

public extension GatewayAPIClient {
	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> EntityResourcesResponse
	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> EntityDetailsResponseDetails
	typealias SubmitTransaction = @Sendable (TransactionSubmitRequest) async throws -> TransactionSubmitResponse
	typealias GetTransactionStatus = @Sendable (TransactionStatusRequest) async throws -> TransactionStatusResponse
}

// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

public extension GatewayAPIClient {
	static let live: Self = .init(
		accountResourcesByAddress: { accountAddress in
			try await Self.mock().accountResourcesByAddress(accountAddress)
		},
		resourceDetailsByResourceIdentifier: { resourceAddress in
			try await Self.mock().resourceDetailsByResourceIdentifier(resourceAddress)
		},
		submitTransaction: { transactionSubmitRequest in
			try await Self.mock().submitTransaction(transactionSubmitRequest)
		},
		transactionStatus: { transactionStatusRequest in
			try await Self.mock().transactionStatus(transactionStatusRequest)
		}
	)
}
