import Common
import Dependencies
import EngineToolkit
import EngineToolkitClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest
	public var signAndSubmitTransaction: SignAndSubmitTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
public extension TransactionClient {
	typealias AddLockFeeInstructionToManifest = @Sendable (TransactionManifest) async throws -> TransactionManifest
	typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	typealias SignAndSubmitTransaction = @Sendable (TransactionManifest, MakeTransactionHeaderInput) async -> TransactionResult
}

public typealias TransactionResult = Swift.Result<TXID, TransactionFailure>

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}
