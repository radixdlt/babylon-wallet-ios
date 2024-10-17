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
	typealias SubmitTransaction = @Sendable (SubmitTXRequest) async throws -> IntentHash
	typealias HasTXBeenCommittedSuccessfully = @Sendable (IntentHash) async throws -> Void
}

// MARK: - SubmitTXRequest
struct SubmitTXRequest: Sendable, Hashable {
	let txID: IntentHash
	let compiledNotarizedTXIntent: CompiledNotarizedIntent
	init(txID: IntentHash, compiledNotarizedTXIntent: CompiledNotarizedIntent) {
		self.txID = txID
		self.compiledNotarizedTXIntent = compiledNotarizedTXIntent
	}
}

// MARK: - TransactionStatusUpdate
struct TransactionStatusUpdate: Sendable, Hashable {
	let txID: IntentHash
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
