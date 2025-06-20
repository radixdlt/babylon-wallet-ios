// MARK: - TransactionClient
struct TransactionClient: Sendable, DependencyKey {
	var getTransactionReview: GetTransactionReview
	var buildTransactionIntent: BuildTransactionIntent
	var notarizeTransaction: NotarizeTransaction
	var myInvolvedEntities: MyInvolvedEntities
	var determineFeePayer: DetermineFeePayer
	var getFeePayerCandidates: GetFeePayerCandidates
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntent
	typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse

	typealias MyInvolvedEntities = @Sendable (TransactionManifest) async throws -> MyEntitiesInvolvedInTransaction
	typealias DetermineFeePayer = @Sendable (DetermineFeePayerRequest) async throws -> FeePayerSelectionResult?
	typealias GetFeePayerCandidates = @Sendable (_ refreshingBalances: Bool) async throws -> IdentifiedArrayOf<FeePayerCandidate>
}

extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - TransactionClient.NotarizeTransactionRequest
extension TransactionClient {
	struct NotarizeTransactionRequest: Sendable {
		let signedIntent: SignedIntent
		let notary: Curve25519.Signing.PrivateKey
	}
}

extension TransactionClient.NotarizeTransactionRequest {
	init(
		intentSignatures: Set<SignatureWithPublicKey>,
		transactionIntent: TransactionIntent,
		notary: Curve25519.Signing.PrivateKey
	) {
		self.notary = notary
		self.signedIntent = .init(
			intent: transactionIntent,
			intentSignatures: IntentSignatures(signatures: Array(intentSignatures.map { IntentSignature(signatureWithPublicKey: $0) }))
		)
	}
}
