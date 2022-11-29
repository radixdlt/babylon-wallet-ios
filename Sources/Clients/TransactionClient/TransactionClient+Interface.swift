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
	typealias SignAndSubmitTransaction = @Sendable (SignManifestRequest) async -> TransactionResult
}

public typealias TransactionResult = Swift.Result<TXID, TransactionFailure>

public extension DependencyValues {
	var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

import Collections
import NonEmpty
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

// MARK: - FaucetClient
/// MOVE TO FaucetClientPackage
struct FaucetClient {
	public struct FaucetRequest: Sendable, Hashable {
		public let recipientAccountAddress: AccountAddress
		public let unlockKeychainPromptShowToUser: String
		public let addLockFeeInstructionToManifest: Bool
		public let makeTransactionHeaderInput: MakeTransactionHeaderInput
		public init(
			recipientAccountAddress: AccountAddress,
			unlockKeychainPromptShowToUser: String,
			addLockFeeInstructionToManifest: Bool = true,
			makeTransactionHeaderInput: MakeTransactionHeaderInput = .default
		) {
			self.recipientAccountAddress = recipientAccountAddress
			self.unlockKeychainPromptShowToUser = unlockKeychainPromptShowToUser
			self.addLockFeeInstructionToManifest = addLockFeeInstructionToManifest
			self.makeTransactionHeaderInput = makeTransactionHeaderInput
		}
	}

	var getFreeXRD: @Sendable (FaucetRequest) async throws -> TXID
	static var liveValue: Self {
		@Dependency(\.transactionClient) var transactionClient
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		@Dependency(\.profileClient) var profileClient

		return Self(getFreeXRD: { faucetRequest in
			let networkID = await profileClient.getCurrentNetworkID()
			let manifest = try engineToolkitClient.manifestForFaucet(
				includeLockFeeInstruction: faucetRequest.addLockFeeInstructionToManifest,
				networkID: networkID,
				accountAddress: faucetRequest.recipientAccountAddress
			)

			let signSubmitTXRequest = SignManifestRequest(
				manifestToSign: manifest,
				makeTransactionHeaderInput: faucetRequest.makeTransactionHeaderInput,
				unlockKeychainPromptShowToUser: faucetRequest.unlockKeychainPromptShowToUser
			)

			return try await transactionClient.signAndSubmitTransaction(signSubmitTXRequest).get()
		})
	}
}
