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
	public typealias SubmitTransaction = @Sendable (CompiledNotarizedIntent) async throws -> IntentHash
	public typealias HasTXBeenCommittedSuccessfully = @Sendable (IntentHash) async throws -> Void
}

// MARK: - PollStrategy
public struct PollStrategy: Sendable, Hashable {
	public let sleepDuration: TimeInterval
	public init(sleepDuration: TimeInterval) {
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(sleepDuration: 2)
}
