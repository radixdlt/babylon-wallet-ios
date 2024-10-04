// MARK: - SubmitTransactionFailure
public enum SubmitTransactionFailure: Sendable, LocalizedError {
	case failedToSubmit
}

// MARK: - SubmitTransactionClient
public struct SubmitTransactionClient: Sendable {
	public var submitTransaction: SubmitTransaction
	public var pollTransactionStatus: PollTransactionStatus
}

extension SubmitTransactionClient {
	public typealias SubmitTransaction = @Sendable (CompiledNotarizedIntent) async throws -> IntentHash
	public typealias PollTransactionStatus = @Sendable (IntentHash) async throws -> Sargon.TransactionStatus
}

extension SubmitTransactionClient {
	func hasTXBeenCommittedSuccessfully(_ intentHash: IntentHash) async throws -> Bool {
		try await pollTransactionStatus(intentHash) == .success
	}
}
