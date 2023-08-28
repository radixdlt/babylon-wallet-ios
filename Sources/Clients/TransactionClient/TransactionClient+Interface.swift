import ClientPrelude
import Cryptography
import EngineKit

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
	public var myInvolvedEntities: MyInvolvedEntities
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntent
	public typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse

	public typealias MyInvolvedEntities = @Sendable (TransactionManifest) async throws -> MyEntitiesInvolvedInTransaction
}

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}
