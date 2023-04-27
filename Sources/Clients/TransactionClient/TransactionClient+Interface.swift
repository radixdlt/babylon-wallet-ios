import ClientPrelude
import Cryptography
import EngineToolkitClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString
	public var lockFeeBySearchingForSuitablePayer: LockFeeBySearchingForSuitablePayer
	public var lockFeeWithSelectedPayer: LockFeeWithSelectedPayer
	public var addGuaranteesToManifest: AddGuaranteesToManifest
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias LockFeeBySearchingForSuitablePayer = @Sendable (TransactionManifest, _ fee: BigDecimal) async throws -> AddFeeToManifestOutcome
	public typealias LockFeeWithSelectedPayer = @Sendable (TransactionManifest, _ fee: BigDecimal, _ payer: AccountAddress) async throws -> TransactionManifest
	public typealias AddGuaranteesToManifest = @Sendable (TransactionManifest, [Guarantee]) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async throws -> TransactionToReview
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async throws -> TransactionIntentWithSigners
	public typealias NotarizeTransaction = @Sendable (NotarizeTransactionRequest) async throws -> NotarizeTransactionResponse
}

// MARK: - NotarizeTransactionRequest
public struct NotarizeTransactionRequest: Sendable, Hashable {
	public let intentSignatures: Set<Engine.SignatureWithPublicKey>
	public let compileTransactionIntent: CompileTransactionIntentResponse
	public let notary: SLIP10.PrivateKey
	public init(
		intentSignatures: Set<Engine.SignatureWithPublicKey>,
		compileTransactionIntent: CompileTransactionIntentResponse,
		notary: SLIP10.PrivateKey
	) {
		self.intentSignatures = intentSignatures
		self.compileTransactionIntent = compileTransactionIntent
		self.notary = notary
	}
}

// MARK: - NotarizeTransactionResponse
public struct NotarizeTransactionResponse: Sendable, Hashable {
	public let notarized: CompileNotarizedTransactionIntentResponse
	public let txID: TXID
	public init(notarized: CompileNotarizedTransactionIntentResponse, txID: TXID) {
		self.notarized = notarized
		self.txID = txID
	}
}

// MARK: - BuildTransactionIntentRequest
public struct BuildTransactionIntentRequest: Sendable {
	public let networkID: NetworkID
	public let manifest: TransactionManifest
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let isFaucetTransaction: Bool
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

	public init(
		networkID: NetworkID,
		manifest: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		isFaucetTransaction: Bool = false,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
	) {
		self.networkID = networkID
		self.manifest = manifest
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.isFaucetTransaction = isFaucetTransaction
		self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
	}
}

// MARK: - TransactionIntentWithSigners
public struct TransactionIntentWithSigners: Sendable, Hashable {
	public let intent: TransactionIntent
	public let transactionSigners: TransactionSigners

	public init(
		intent: TransactionIntent,
		transactionSigners: TransactionSigners
	) {
		self.intent = intent
		self.transactionSigners = transactionSigners
	}
}

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - TransactionClient.Guarantee
extension TransactionClient {
	public struct Guarantee: Sendable, Hashable {
		public var amount: BigDecimal
		public var instructionIndex: UInt32
		public var resourceAddress: ResourceAddress

		public init(
			amount: BigDecimal,
			instructionIndex: UInt32,
			resourceAddress: ResourceAddress
		) {
			self.amount = amount
			self.instructionIndex = instructionIndex
			self.resourceAddress = resourceAddress
		}
	}
}

// MARK: - ManifestReviewRequest
public struct ManifestReviewRequest: Sendable {
	public let manifestToSign: TransactionManifest
	public let feeToAdd: BigDecimal
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

	public init(
		manifestToSign: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		feeToAdd: BigDecimal,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey = Curve25519.Signing.PrivateKey().publicKey
	) {
		self.manifestToSign = manifestToSign
		self.feeToAdd = feeToAdd
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
	}
}

// MARK: - FeePayerCandiate
public struct FeePayerCandiate: Sendable, Hashable, Identifiable {
	public let account: Profile.Network.Account
	public let xrdBalance: BigDecimal
	public typealias ID = Profile.Network.Account.ID
	public var id: ID { account.id }
}

// MARK: - AddFeeToManifestOutcome
public enum AddFeeToManifestOutcome: Sendable, Equatable {
	case includesLockFee(TransactionManifest, feePayer: FeePayerSelectionAmongstCandidates)
	case excludesLockFee(TransactionManifest, feePayerCandidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>, feeNotYetAdded: BigDecimal)
}

// MARK: - TransactionToReview
public struct TransactionToReview: Sendable, Equatable {
	public let analyzedManifestToReview: AnalyzeManifestWithPreviewContextResponse
	public let addFeeToManifestOutcome: AddFeeToManifestOutcome
	public let networkID: NetworkID
}

// MARK: - FeePayerSelectionAmongstCandidates
public struct FeePayerSelectionAmongstCandidates: Sendable, Hashable {
	public enum Selection: Sendable, Hashable {
		case selectedByUser
		case auto
	}

	public let selected: FeePayerCandiate
	/// contains `selected`
	public let candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>

	public let fee: BigDecimal

	public let selection: Selection

	public init(
		selected: FeePayerCandiate,
		candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>,
		fee: BigDecimal,
		selection: Selection
	) {
		self.selected = selected
		self.candidates = candidates
		self.fee = fee
		self.selection = selection
	}
}
