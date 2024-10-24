// MARK: - SubmitTransactionFailure
enum SubmitTransactionFailure: Sendable, LocalizedError {
	case failedToSubmit
}

// MARK: - SubmitTransactionClient
struct SubmitTransactionClient: Sendable {
	var submitTransaction: SubmitTransaction
	var hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully
}

extension SubmitTransactionClient {
	typealias SubmitTransaction = @Sendable (SubmitTXRequest) async throws -> TransactionIntentHash
	typealias HasTXBeenCommittedSuccessfully = @Sendable (TransactionIntentHash) async throws -> Void
}

// MARK: - SubmitTXRequest
struct SubmitTXRequest: Sendable, Hashable {
	let txID: TransactionIntentHash
	let compiledNotarizedTXIntent: CompiledNotarizedIntent
	init(txID: TransactionIntentHash, compiledNotarizedTXIntent: CompiledNotarizedIntent) {
		self.txID = txID
		self.compiledNotarizedTXIntent = compiledNotarizedTXIntent
	}
}

// MARK: - TransactionStatusUpdate
struct TransactionStatusUpdate: Sendable, Hashable {
	let txID: TransactionIntentHash
	let result: Loadable<EqVoid>
}

// MARK: - PollStrategy
struct PollStrategy: Sendable, Hashable {
	let sleepDuration: TimeInterval
	init(sleepDuration: TimeInterval) {
		self.sleepDuration = sleepDuration
	}

	static let `default` = Self(sleepDuration: 2)
}
