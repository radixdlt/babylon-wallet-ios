import ClientPrelude
import Cryptography
import EngineToolkitClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var lockFeeBySearchingForSuitablePayer: LockFeeBySearchingForSuitablePayer
	public var lockFeeWithSelectedPayer: LockFeeWithSelectedPayer
	public var addGuaranteesToManifest: AddGuaranteesToManifest
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias LockFeeBySearchingForSuitablePayer = @Sendable (TransactionManifest, _ fee: BigDecimal) async throws -> AddFeeToManifestOutcome
	public typealias LockFeeWithSelectedPayer = @Sendable (TransactionManifest, _ fee: BigDecimal, _ payer: AccountAddress) async throws -> TransactionManifest
	public typealias AddGuaranteesToManifest = @Sendable (TransactionManifest, [Guarantee]) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntentWithSigners
	public typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse
}

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}
