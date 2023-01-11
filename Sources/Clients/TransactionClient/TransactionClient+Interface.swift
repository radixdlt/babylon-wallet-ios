import Common
import EngineToolkit
import EngineToolkitClient
import Prelude

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
	typealias SignAndSubmitTransaction = @Sendable (SignManifestRequest) async -> TransactionResult
}

public typealias TransactionResult = Swift.Result<TXID, TransactionFailure>

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

import Prelude
import Profile
import ProfileClient

// MARK: - SignManifestRequest
public struct SignManifestRequest: Sendable {
	public let manifestToSign: TransactionManifest
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let unlockKeychainPromptShowToUser: String
	public let selectNotary: @Sendable (NonEmpty<OrderedSet<SignersOfAccount>>) async -> SignersOfAccount

	public init(
		manifestToSign: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput,
		unlockKeychainPromptShowToUser: String,
		selectNotary: @escaping @Sendable (NonEmpty<OrderedSet<SignersOfAccount>>) -> SignersOfAccount = { $0.first }
	) {
		self.manifestToSign = manifestToSign
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.unlockKeychainPromptShowToUser = unlockKeychainPromptShowToUser
		self.selectNotary = selectNotary
	}
}
