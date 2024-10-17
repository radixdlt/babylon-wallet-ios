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
	typealias SubmitTransaction = @Sendable (NotarizedTransaction) async throws -> IntentHash
	typealias PollTransactionStatus = @Sendable (IntentHash) async throws -> Sargon.TransactionStatus
}

extension SubmitTransactionClient {
	func hasTXBeenCommittedSuccessfully(_ intentHash: IntentHash) async throws -> Bool {
		try await pollTransactionStatus(intentHash) == .success
	}
}
