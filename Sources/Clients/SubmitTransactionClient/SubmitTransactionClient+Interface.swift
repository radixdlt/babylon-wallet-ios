import ClientPrelude
import EngineToolkitModels
import GatewayAPI

// MARK: - SubmitTransactionFailure
public enum SubmitTransactionFailure: Sendable, LocalizedError {
	case failedToSubmit
}

// MARK: - TransactionPollingFailure
public enum TransactionPollingFailure: Sendable, LocalizedError, Hashable {
	case failedToPollTX(txID: TXID, error: FailedToPollError)
	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: TXFailureStatus)
	public func hash(into hasher: inout Hasher) {
		hasher.combine(errorDescription)
	}

	public var errorDescription: String? {
		switch self {
		case let .failedToPollTX(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .failedToGetTransactionStatus(txID, error):
			return "\(error.localizedDescription) txID: \(txID)"
		case let .invalidTXWasSubmittedButNotSuccessful(txID, status):
			return "Invalid TX submitted but not successful, status: \(status.localizedDescription) txID: \(txID)"
		}
	}
}

// MARK: - SubmitTransactionClient
public struct SubmitTransactionClient: Sendable {
	public var submitTransaction: SubmitTransaction
	public var transactionStatusUpdates: TransactionStatusUpdates
	public var hasTXBeenCommittedSuccessfully: HasTXBeenCommittedSuccessfully
}

extension SubmitTransactionClient {
	public typealias SubmitTransaction = @Sendable (SubmitTXRequest) async throws -> TXID
	public typealias TransactionStatusUpdates = @Sendable (TXID, PollStrategy) async throws -> AnyAsyncSequence<TransactionStatusUpdate>
	public typealias HasTXBeenCommittedSuccessfully = @Sendable (TXID) async throws -> Void
}

// MARK: - SubmitTXRequest
public struct SubmitTXRequest: Sendable, Hashable {
	public let txID: TXID
	public let compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse
	public init(txID: TXID, compiledNotarizedTXIntent: CompileNotarizedTransactionIntentResponse) {
		self.txID = txID
		self.compiledNotarizedTXIntent = compiledNotarizedTXIntent
	}
}

// MARK: - TransactionStatusUpdate
public struct TransactionStatusUpdate: Sendable, Hashable {
	public let txID: TXID
	//    public let status: TransactionStatus
	public let result: Result<TransactionStatus, TransactionPollingFailure>
}

// MARK: - PollStrategy
public struct PollStrategy: Sendable, Hashable {
	public let maxPollTries: Int
	public let sleepDuration: TimeInterval
	public init(maxPollTries: Int, sleepDuration: TimeInterval) {
		self.maxPollTries = maxPollTries
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(maxPollTries: 20, sleepDuration: 2)
}
