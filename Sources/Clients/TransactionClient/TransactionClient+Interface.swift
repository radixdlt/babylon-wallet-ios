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
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
	public typealias LockFeeBySearchingForSuitablePayer = @Sendable (TransactionManifest, _ fee: BigDecimal) async throws -> AddFeeToManifestOutcome
	public typealias LockFeeWithSelectedPayer = @Sendable (TransactionManifest, _ fee: BigDecimal, _ payer: AccountAddress) async throws -> TransactionManifest
	public typealias AddGuaranteesToManifest = @Sendable (TransactionManifest, [Guarantee]) async throws -> TransactionManifest
	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (TransactionManifest) async throws -> JSONInstructionsTransactionManifest
	public typealias GetTransactionReview = @Sendable (ManifestReviewRequest) async -> TransactionReviewResult
	public typealias BuildTransactionIntent = @Sendable (BuildTransactionIntentRequest) async -> BuildTransactionIntentResult
}

// MARK: - BuildTransactionIntentRequest
public struct BuildTransactionIntentRequest: Sendable {
	public let networkID: NetworkID
	public let manifest: TransactionManifest
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let selectNotary: SelectNotary

	public init(
		networkID: NetworkID,
		manifest: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		selectNotary: @escaping SelectNotary = { .init(notary: .account($0.first)) }
	) {
		self.networkID = networkID
		self.manifest = manifest
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.selectNotary = selectNotary
	}
}

public typealias BuildTransactionIntentResult = Result<TransactionIntentWithSigners, TransactionFailure.FailedToPrepareForTXSigning>

// MARK: - TransactionIntentWithSigners
public struct TransactionIntentWithSigners: Sendable, Hashable {
	public let intent: TransactionIntent
	public let notaryAndSigners: NotaryAndSigners
	public let signerPublicKeys: [Engine.PublicKey]
}

public typealias TransactionReviewResult = Swift.Result<TransactionToReview, TransactionFailure>

extension DependencyValues {
	public var transactionClient: TransactionClient {
		get { self[TransactionClient.self] }
		set { self[TransactionClient.self] = newValue }
	}
}

// MARK: - NotarySelection
public struct NotarySelection: Sendable, Hashable {
	public let notary: Notary
	public let notaryAsSignatory: Bool

	public enum Notary: Sendable, Hashable {
		case ephemeralPublicKey(SLIP10.PublicKey)
		case account(Profile.Network.Account)

		public var notaryPublicKey: SLIP10.PublicKey {
			switch self {
			case let .ephemeralPublicKey(publicKey): return publicKey
			case let .account(account):
				switch account.securityState {
				case let .unsecured(entityControl): return entityControl.genesisFactorInstance.publicKey
				}
			}
		}
	}

	public var notaryPublicKey: SLIP10.PublicKey {
		notary.notaryPublicKey
	}

	public init(
		notary: Notary,
		notaryAsSignatory: Bool = false
	) {
		self.notary = notary
		self.notaryAsSignatory = notaryAsSignatory
	}
}

public typealias SelectNotary = @Sendable (NonEmpty<OrderedSet<Profile.Network.Account>>) async -> NotarySelection

// MARK: - TransactionClient.Guarantee
extension TransactionClient {
	public struct Guarantee: Sendable, Hashable {
		public var amount: BigDecimal
		public var instructionIndex: UInt32
		public var resourceAddress: ResourceAddress

		public init(amount: BigDecimal, instructionIndex: UInt32, resourceAddress: ResourceAddress) {
			self.amount = amount
			self.instructionIndex = instructionIndex
			self.resourceAddress = resourceAddress
		}
	}
}

// MARK: - ManifestReviewRequest
// Duplicated for now, very similar to SignManifestRequest
public struct ManifestReviewRequest: Sendable {
	public let manifestToSign: TransactionManifest
	public let feeToAdd: BigDecimal
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let selectNotary: SelectNotary

	public init(
		manifestToSign: TransactionManifest,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		feeToAdd: BigDecimal,
		selectNotary: @escaping SelectNotary = { .init(notary: .account($0.first)) }
	) {
		self.manifestToSign = manifestToSign
		self.feeToAdd = feeToAdd
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.selectNotary = selectNotary
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
