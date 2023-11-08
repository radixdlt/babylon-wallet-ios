// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
	public var myInvolvedEntities: MyInvolvedEntities
	public var determineFeePayer: DetermineFeePayer
	public var getFeePayerCandidates: GetFeePayerCandidates
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntent
	public typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse

	public typealias MyInvolvedEntities = @Sendable (TransactionManifest) async throws -> MyEntitiesInvolvedInTransaction
	public typealias DetermineFeePayer = @Sendable (DetermineFeePayerRequest) async throws -> FeePayerSelectionResult?
	public typealias GetFeePayerCandidates = @Sendable (_ refreshingBalances: Bool) async throws -> NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
}

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}
