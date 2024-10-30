// MARK: - SubmitTransactionFailure
enum SubmitTransactionFailure: Sendable, LocalizedError {
	case failedToSubmit
}

// MARK: - SubmitTransactionClient
struct SubmitTransactionClient: Sendable {
	var submitTransaction: SubmitTransaction
	var pollTransactionStatus: PollTransactionStatus
}

extension SubmitTransactionClient {
	typealias SubmitTransaction = @Sendable (NotarizedTransaction) async throws -> TransactionIntentHash
	typealias PollTransactionStatus = @Sendable (TransactionIntentHash) async throws -> Sargon.TransactionStatus
}

extension SubmitTransactionClient {
	func hasTXBeenCommittedSuccessfully(_ intentHash: TransactionIntentHash) async throws -> Bool {
		try await pollTransactionStatus(intentHash) == .success
	}
}
