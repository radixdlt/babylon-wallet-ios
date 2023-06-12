import ClientPrelude
import Cryptography
import EngineToolkitClient
import FactorSourcesClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var convertManifestToString: ConvertManifestToString
	public var lockFeeBySearchingForSuitablePayer: LockFeeBySearchingForSuitablePayer
	public var lockFeeWithSelectedPayer: LockFeeWithSelectedPayer
	public var addInstructionToManifest: AddInstructionToManifest
	public var addGuaranteesToManifest: AddGuaranteesToManifest
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
	public var prepareForSigning: PrepareForSigning
	public var myInvolvedEntities: MyInvolvedEntities
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias AddInstructionToManifest = @Sendable (AddInstructionToManifestRequest) async throws -> TransactionManifest
	public typealias LockFeeBySearchingForSuitablePayer = @Sendable (TransactionManifest, _ fee: BigDecimal) async throws -> AddFeeToManifestOutcome
	public typealias LockFeeWithSelectedPayer = @Sendable (TransactionManifest, _ fee: BigDecimal, _ payer: AccountAddress) async throws -> TransactionManifest
	public typealias AddGuaranteesToManifest = @Sendable (TransactionManifest, [Guarantee]) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias ConvertManifestToString = @Sendable (TransactionManifest) async throws -> TransactionManifest

	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntentWithSigners
	public typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse

	public typealias PrepareForSigning = @Sendable (PrepareForSigningRequest) async throws -> PrepareForSiginingResponse
	public typealias MyInvolvedEntities = @Sendable (TransactionManifest) async throws -> MyEntitiesInvolvedInTransaction
}

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - AddInstructionToManifestLocation
public enum AddInstructionToManifestLocation: Sendable, Hashable {
	case first
	public static let lockFee: Self = .first
}

// MARK: - AddInstructionToManifestRequest
public struct AddInstructionToManifestRequest: Sendable, Hashable {
	public let instruction: Instruction
	public let manifest: TransactionManifest
	public let location: AddInstructionToManifestLocation
	public init(
		instruction: Instruction,
		to manifest: TransactionManifest,
		at location: AddInstructionToManifestLocation
	) {
		self.instruction = instruction
		self.manifest = manifest
		self.location = location
	}

	public init(
		_ instruction: any InstructionProtocol,
		to manifest: TransactionManifest,
		at location: AddInstructionToManifestLocation
	) {
		self.init(instruction: instruction.embed(), to: manifest, at: location)
	}
}

extension TransactionClient {
	public struct PrepareForSigningRequest: Equatable, Sendable {
		public let nonce: Nonce
		public let manifest: TransactionManifest
		public let feePayer: Profile.Network.Account
		public let networkID: NetworkID
		public let purpose: SigningPurpose

		public var compiledIntent: CompileTransactionIntentResponse? = nil
		public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

		public init(
			nonce: Nonce,
			manifest: TransactionManifest,
			networkID: NetworkID,
			feePayer: Profile.Network.Account,
			purpose: SigningPurpose,
			ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
		) {
			self.nonce = nonce
			self.manifest = manifest
			self.networkID = networkID
			self.feePayer = feePayer
			self.purpose = purpose
			self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
		}
	}

	public struct PrepareForSiginingResponse: Equatable, Sendable {
		public let compiledIntent: CompileTransactionIntentResponse
		public let signingFactors: SigningFactors

		public init(compiledIntent: CompileTransactionIntentResponse, signingFactors: SigningFactors) {
			self.compiledIntent = compiledIntent
			self.signingFactors = signingFactors
		}
	}
}
