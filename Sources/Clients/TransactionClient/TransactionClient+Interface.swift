import ClientPrelude
import EngineToolkitClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var addLockFeeInstructionToManifest: AddLockFeeInstructionToManifest
	public var signAndSubmitTransaction: SignAndSubmitTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias AddLockFeeInstructionToManifest = @Sendable (TransactionManifest) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias SignAndSubmitTransaction = @Sendable (SignManifestRequest) async -> TransactionResult
}

public typealias TransactionResult = Swift.Result<TXID, TransactionFailure>

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - SignManifestRequest
public struct SignManifestRequest: Sendable {
	public let manifestToSign: TransactionManifest
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public typealias SelectNotary = @Sendable (NonEmpty<OrderedSet<Profile.Network.Account>>) async -> Profile.Network.Account
	public let selectNotary: SelectNotary

	public init(
		manifestToSign: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput,
		selectNotary: @escaping SelectNotary = { $0.first }
	) {
		self.manifestToSign = manifestToSign
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.selectNotary = selectNotary
	}
}
