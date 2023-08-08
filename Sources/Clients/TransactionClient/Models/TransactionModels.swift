import Cryptography
import EngineKit
import GatewayAPI
import Prelude
import Profile

// MARK: - TransactionSigners
public struct TransactionSigners: Sendable, Hashable {
	public let notaryPublicKey: Curve25519.Signing.PublicKey
	public let intentSigning: IntentSigning

	public enum IntentSigning: Sendable, Hashable {
		case notaryIsSignatory
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
		let flags = GatewayAPI.TransactionPreviewRequestFlags(
			useFreeCredit: true,
			assumeAllSignatureProofs: false,
			skipEpochCheck: false
		)

		struct NotaryIsSignatoryDiscrepancy: Swift.Error {}
		guard transactionSigners.notaryIsSignatory == header.notaryIsSignatory else {
			loggerGlobal.error("Preview incorrectly implemented, found discrepancy in `notaryIsSignatory` and `transactionSigners`.")
			assertionFailure("discrepancy")
			throw NotaryIsSignatoryDiscrepancy()
		}
		let notaryIsSignatory = transactionSigners.notaryIsSignatory

		try self.init(
			manifest: rawManifest.instructions().asStr(),
			blobsHex: rawManifest.blobs().map(\.hex),
			startEpochInclusive: .init(header.startEpochInclusive),
			endEpochExclusive: .init(header.endEpochExclusive),
			notaryPublicKey: GatewayAPI.PublicKey(from: header.notaryPublicKey),
			notaryIsSignatory: notaryIsSignatory,
			tipPercentage: .init(header.tipPercentage),
			nonce: .init(header.nonce),
			signerPublicKeys: transactionSigners.signerPublicKeys.map(GatewayAPI.PublicKey.init(from:)),
			flags: flags
		)
	}
}

extension TransactionSigners {
	public var notaryIsSignatory: Bool {
		switch self.intentSigning {
		case .intentSigners: return false
		case .notaryIsSignatory: return true
		}
	}

	public var signerPublicKeys: Set<SLIP10.PublicKey> {
		switch intentSigning {
		case let .intentSigners(signers):
			return Set(signers.flatMap { $0.virtualHierarchicalDeterministicFactorInstances.map(\.publicKey) })
		case .notaryIsSignatory:
			return []
		}
	}

	public func intentSignerEntitiesOrEmpty() -> OrderedSet<EntityPotentiallyVirtual> {
		switch intentSigning {
		case .notaryIsSignatory: return .init()
		case let .intentSigners(signers): return OrderedSet(signers)
		}
	}
}

extension GatewayAPI.PublicKey {
	init(from engine: EngineToolkit.PublicKey) {
		switch engine {
		case let .secp256k1(bytes):
			self = .ecdsaSecp256k1(.init(keyType: .ecdsaSecp256k1, keyHex: bytes.hex()))
		case let .ed25519(bytes):
			self = .eddsaEd25519(.init(keyType: .eddsaEd25519, keyHex: bytes.hex()))
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
	public let intentSignatures: Set<EngineToolkit.SignatureWithPublicKey>
	public let transactionIntent: TransactionIntent
	public let notary: SLIP10.PrivateKey
	public init(
		intentSignatures: Set<EngineToolkit.SignatureWithPublicKey>,
		transactionIntent: TransactionIntent,
		notary: SLIP10.PrivateKey
	) {
		self.intentSignatures = intentSignatures
		self.transactionIntent = transactionIntent
		self.notary = notary
	}
}

// MARK: - NotarizeTransactionResponse
public struct NotarizeTransactionResponse: Sendable, Hashable {
	public let notarized: [UInt8]
	public let txID: TXID
	public init(notarized: [UInt8], txID: TXID) {
		self.notarized = notarized
		self.txID = txID
	}
}

// MARK: - BuildTransactionIntentRequest
public struct BuildTransactionIntentRequest: Sendable {
	public let networkID: NetworkID
	public let nonce: Nonce
	public let manifest: TransactionManifest
	public let message: Message
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let isFaucetTransaction: Bool
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

	public init(
		networkID: NetworkID,
		manifest: TransactionManifest,
		message: Message,
		nonce: Nonce = .secureRandom(),
		makeTransactionHeaderInput: MakeTransactionHeaderInput,
		isFaucetTransaction: Bool = false,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
	) {
		self.networkID = networkID
		self.manifest = manifest
		self.message = message
		self.nonce = nonce
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
		public var instructionIndex: UInt64
		public var resourceAddress: ResourceAddress

		public init(
			amount: BigDecimal,
			instructionIndex: UInt64,
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
	public let message: Message
	public let nonce: Nonce
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

	public init(
		manifestToSign: TransactionManifest,
		message: Message,
		nonce: Nonce,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey = Curve25519.Signing.PrivateKey().publicKey
	) {
		self.manifestToSign = manifestToSign
		self.message = message
		self.nonce = nonce
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
	}
}

// MARK: - FeePayerCandidate
public struct FeePayerCandidate: Sendable, Hashable, Identifiable {
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
	public let feePayerCandidates: IdentifiedArrayOf<FeePayerCandidate>
	public let feeNotYetAdded: BigDecimal
}

// MARK: - TransactionToReview
public struct TransactionToReview: Sendable, Equatable {
	public let analyzedManifestToReview: ExecutionAnalysis
	public let networkID: NetworkID
	public let feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
}

// MARK: - FeePayerSelectionAmongstCandidates
public struct FeePayerSelectionAmongstCandidates: Sendable, Hashable {
	public var selected: FeePayerCandidate?
	/// contains `selected`
	public let candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
	public var transactionFee: TransactionFee

	public init(
		selected: FeePayerCandidate?,
		candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>,
		transactionFee: TransactionFee
	) {
		self.selected = selected
		self.candidates = candidates
		self.transactionFee = transactionFee
	}
}

// MARK: - TransactionFee
public struct TransactionFee: Hashable, Sendable {
	let feeSummary: FeeSummary
	let feeLocks: FeeLocks
	public var mode: Mode = .normal

	public init(feeSummary: FeeSummary, feeLocks: FeeLocks, mode: Mode) {
		self.feeSummary = feeSummary
		self.feeLocks = feeLocks
		self.mode = mode
	}

	public init(executionAnalysis: ExecutionAnalysis) throws {
		let feeSummary: FeeSummary = try .init(
			networkFee: .init(executionAnalysis.feeSummary.networkFee),
			royaltyFee: .init(executionAnalysis.feeSummary.royaltyFee)
		)
		let feeLocks: FeeLocks = try .init(
			nonContingentLock: .init(executionAnalysis.feeLocks.lock),
			contingentLock: .init(executionAnalysis.feeLocks.contingentLock)
		)

		self.init(
			feeSummary: feeSummary,
			feeLocks: feeLocks,
			mode: .normal
		)
	}
}

extension TransactionFee {
	public var networkFee: BigDecimal {
		max(feeSummary.networkFee - feeLocks.nonContingentLock, .zero)
	}

	public var royaltyFee: BigDecimal {
		let remainingNonContingentLock = max(feeLocks.nonContingentLock - feeSummary.networkFee, .zero)
		return max(feeSummary.royaltyFee - remainingNonContingentLock, .zero)
	}

	public var totalFee: TotalFee {
		switch mode {
		case .normal:
			let maxFee = networkFee + royaltyFee
			let minFee = max(maxFee - feeLocks.contingentLock, .zero)
			return .init(min: minFee, max: maxFee)
		case let .advanced(advanced):
			let networkFee = max(advanced.networkAndRoyaltyFee - royaltyFee, .zero)
			let tipAmount = networkFee * (advanced.tipPercentage / 100)
			let total = advanced.networkAndRoyaltyFee + tipAmount
			return .init(min: total, max: total)
		}
	}

	public mutating func toggleMode() {
		switch mode {
		case .normal:
			mode = .advanced(.init(networkAndRoyaltyFee: networkFee + royaltyFee, tipPercentage: .zero))
		case .advanced:
			mode = .normal
		}
	}
}

extension TransactionFee {
	public enum Mode: Hashable, Sendable {
		case normal
		case advanced(AdvancedFeeCustomization)
	}

	public struct FeeSummary: Hashable, Sendable {
		let networkFee: BigDecimal
		let royaltyFee: BigDecimal

		public init(networkFee: BigDecimal, royaltyFee: BigDecimal) {
			self.networkFee = networkFee * 1.15
			self.royaltyFee = royaltyFee
		}
	}

	public struct FeeLocks: Hashable, Sendable {
		let nonContingentLock: BigDecimal
		let contingentLock: BigDecimal

		public init(nonContingentLock: BigDecimal, contingentLock: BigDecimal) {
			self.nonContingentLock = nonContingentLock
			self.contingentLock = contingentLock
		}
	}

	public struct AdvancedFeeCustomization: Hashable, Sendable {
		public var networkAndRoyaltyFee: BigDecimal
		public var tipPercentage: BigDecimal

		public init(networkAndRoyaltyFee: BigDecimal, tipPercentage: BigDecimal) {
			self.networkAndRoyaltyFee = networkAndRoyaltyFee
			self.tipPercentage = tipPercentage
		}
	}

	public struct TotalFee: Hashable, Sendable {
		let min: BigDecimal
		let max: BigDecimal

		public var lockFee: BigDecimal {
			// We always lock the max amount
			max
		}

		public var displayedTotalFee: String {
			if max > min {
				return "\(min.format()) - \(max.format()) XRD"
			}
			return "\(max.format()) XRD"
		}
	}
}
