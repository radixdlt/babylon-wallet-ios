// MARK: - TransactionClient
struct TransactionClient: Sendable, DependencyKey {
	var getTransactionReview: GetTransactionReview
	var buildTransactionIntent: BuildTransactionIntent
	var notarizeTransaction: NotarizeTransaction
	var newNotarizeTransaction: NewNotarizeTransaction
	var myInvolvedEntities: MyInvolvedEntities
	var determineFeePayer: DetermineFeePayer
	var getFeePayerCandidates: GetFeePayerCandidates
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntent
	typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse
	typealias NewNotarizeTransaction = @Sendable (NewNotarizeTransactionRequest) async throws -> NotarizeTransactionResponse

	typealias MyInvolvedEntities = @Sendable (TransactionManifest) async throws -> MyEntitiesInvolvedInTransaction
	typealias DetermineFeePayer = @Sendable (DetermineFeePayerRequest) async throws -> FeePayerSelectionResult?
	typealias GetFeePayerCandidates = @Sendable (_ refreshingBalances: Bool) async throws -> NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
}

extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - TransactionClient.NewNotarizeTransactionRequest
extension TransactionClient {
	struct NewNotarizeTransactionRequest: Sendable {
		let transactionIntent: TransactionIntent
		let signedIntent: SignedIntent
		let notary: Curve25519.Signing.PrivateKey
	}
}
