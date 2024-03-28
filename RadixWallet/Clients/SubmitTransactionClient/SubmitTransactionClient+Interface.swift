// MARK: - SubmitTransactionFailure
public enum SubmitTransactionFailure: Sendable, LocalizedError {
	case failedToSubmit
}

// MARK: - SubmitTransactionClient
public struct SubmitTransactionClient: Sendable {
	public var submitTransaction: SubmitTransaction
	public var hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully
}

extension SubmitTransactionClient {
	public typealias SubmitTransaction = @Sendable (SubmitTXRequest) async throws -> TXID
	public typealias HasTXBeenCommittedSuccessfully = @Sendable (TXID) async throws -> Void
}

// MARK: - SubmitTXRequest
public struct SubmitTXRequest: Sendable, Hashable {
	public let txID: TXID
	public let compiledNotarizedTXIntent: CompiledNotarizedIntent
	public init(txID: TXID, compiledNotarizedTXIntent: CompiledNotarizedIntent) {
		self.txID = txID
		self.compiledNotarizedTXIntent = compiledNotarizedTXIntent
	}
}

// MARK: - TransactionStatusUpdate
public struct TransactionStatusUpdate: Sendable, Hashable {
	public let txID: TXID
	public let result: Loadable<EqVoid>
}

// MARK: - PollStrategy
public struct PollStrategy: Sendable, Hashable {
	public let sleepDuration: TimeInterval
	public init(sleepDuration: TimeInterval) {
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(sleepDuration: 2)
}
