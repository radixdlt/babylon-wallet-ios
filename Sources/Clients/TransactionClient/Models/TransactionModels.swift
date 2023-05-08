import Cryptography
import EngineToolkitModels
import GatewayAPI
import Prelude
import Profile

// MARK: - TransactionSigners
public struct TransactionSigners: Sendable, Hashable {
	public let notaryPublicKey: Curve25519.Signing.PublicKey
	public let intentSigning: IntentSigning

	public enum IntentSigning: Sendable, Hashable {
		case notaryAsSignatory
		case intentSigners(NonEmpty<OrderedSet<EntityPotentiallyVirtual>>)
	}

	public init(
		notaryPublicKey: Curve25519.Signing.PublicKey,
		intentSigning: IntentSigning
	) {
		self.notaryPublicKey = notaryPublicKey
		self.intentSigning = intentSigning
	}
}

extension GatewayAPI.TransactionPreviewRequest {
	init(
		rawManifest: TransactionManifest,
		header: TransactionHeader,
		transactionSigners: TransactionSigners
	) throws {
		let manifestString = {
			switch rawManifest.instructions {
			case let .string(manifestString): return manifestString
			case .parsed: fatalError("you should have converted manifest to string first")
			}
		}()

		let flags = GatewayAPI.TransactionPreviewRequestFlags(
			unlimitedLoan: true, // True since no lock fee is added
			assumeAllSignatureProofs: false,
			permitDuplicateIntentHash: false,
			permitInvalidHeaderEpoch: false
		)

		struct NotaryAsSignatoryDiscrepancy: Swift.Error {}
		guard transactionSigners.notaryAsSignatory == header.notaryAsSignatory else {
			loggerGlobal.error("Preview incorrectly implemented, found discrepancy in `notaryAsSignatory` and `transactionSigners`.")
			assertionFailure("discrepancy")
			throw NotaryAsSignatoryDiscrepancy()
		}
		let notaryAsSignatory = transactionSigners.notaryAsSignatory

		self.init(
			manifest: manifestString,
			blobsHex: rawManifest.blobs.map(\.hex),
			startEpochInclusive: .init(header.startEpochInclusive.rawValue),
			endEpochExclusive: .init(header.endEpochExclusive.rawValue),
			notaryPublicKey: GatewayAPI.PublicKey(from: header.publicKey),
			notaryAsSignatory: notaryAsSignatory,
			costUnitLimit: .init(header.costUnitLimit),
			tipPercentage: .init(header.tipPercentage),
			nonce: .init(header.nonce.rawValue),
			signerPublicKeys: transactionSigners.signerPublicKeys.map(GatewayAPI.PublicKey.init(from:)),
			flags: flags
		)
	}
}

extension TransactionSigners {
	public var notaryAsSignatory: Bool {
		switch self.intentSigning {
		case .intentSigners: return false
		case .notaryAsSignatory: return true
		}
	}

	public var signerPublicKeys: Set<SLIP10.PublicKey> {
		switch intentSigning {
		case let .intentSigners(signers):
			return Set(signers.flatMap { $0.factorInstances.map(\.publicKey) })
		case .notaryAsSignatory:
			return []
		}
	}

	public func intentSignerEntitiesOrEmpty() -> OrderedSet<EntityPotentiallyVirtual> {
		switch intentSigning {
		case .notaryAsSignatory: return .init()
		case let .intentSigners(signers): return OrderedSet(signers)
		}
	}
}

extension GatewayAPI.PublicKey {
	init(from engine: Engine.PublicKey) {
		switch engine {
		case let .ecdsaSecp256k1(key):
			self = .ecdsaSecp256k1(.init(keyType: .ecdsaSecp256k1, keyHex: key.bytes.hex))
		case let .eddsaEd25519(key):
			self = .eddsaEd25519(.init(keyType: .eddsaEd25519, keyHex: key.bytes.hex))
		}
	}
}

extension GatewayAPI.PublicKey {
	init(from slip10: SLIP10.PublicKey) {
		switch slip10 {
		case let .eddsaEd25519(pubKey):
			self = .eddsaEd25519(.init(keyType: .eddsaEd25519, keyHex: pubKey.rawRepresentation.hex))
		case let .ecdsaSecp256k1(pubKey):
			self = .ecdsaSecp256k1(.init(keyType: .ecdsaSecp256k1, keyHex: pubKey.compressedRepresentation.hex))
		}
	}
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
	case includesLockFee(AddFeeToManifestOutcomeIncludesLockFee)
	case excludesLockFee(AddFeeToManifestOutcomeExcludesLockFee)
}

// MARK: - AddFeeToManifestOutcomeIncludesLockFee
public struct AddFeeToManifestOutcomeIncludesLockFee: Sendable, Equatable {
	public let manifestWithLockFee: TransactionManifest
	public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
}

// MARK: - AddFeeToManifestOutcomeExcludesLockFee
public struct AddFeeToManifestOutcomeExcludesLockFee: Sendable, Equatable {
	public let manifestExcludingLockFee: TransactionManifest
	public let feePayerCandidates: NonEmpty<IdentifiedArrayOf<FeePayerCandiate>>
	public let feeNotYetAdded: BigDecimal
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
