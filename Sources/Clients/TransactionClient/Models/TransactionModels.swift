import Cryptography
import EngineKit
import FactorSourcesClient
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
	public let transactionSigners: TransactionSigners

	public init(
		networkID: NetworkID,
		manifest: TransactionManifest,
		message: Message,
		nonce: Nonce = .secureRandom(),
		makeTransactionHeaderInput: MakeTransactionHeaderInput,
		transactionSigners: TransactionSigners
	) {
		self.networkID = networkID
		self.manifest = manifest
		self.message = message
		self.nonce = nonce
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.transactionSigners = transactionSigners
	}
}

// MARK: - GetTransactionSignersRequest
public struct GetTransactionSignersRequest: Sendable, Hashable {
	public let networkID: NetworkID
	public let manifest: TransactionManifest
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey

	public init(networkID: NetworkID, manifest: TransactionManifest, ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey) {
		self.networkID = networkID
		self.manifest = manifest
		self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
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
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
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
	public typealias ID = Profile.Network.Account.ID
	public var id: ID { account.id }

	public let account: Profile.Network.Account
	public let xrdBalance: BigDecimal
}

// MARK: - TransactionToReview
public struct TransactionToReview: Sendable, Hashable {
	public let analyzedManifestToReview: ExecutionAnalysis
	public let networkID: NetworkID

	public var feePayerSelectionAmongstCandidates: FeePayerSelectionAmongstCandidates
	public var transactionSigners: TransactionSigners
	public var signingFactors: SigningFactors
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
	/// FeeSummary after transaction was analyzed
	public let feeSummary: FeeSummary

	/// FeeLocks after transaction was analyzed
	public let feeLocks: FeeLocks

	/// The calculation mode
	public var mode: Mode

	public init(feeSummary: FeeSummary, feeLocks: FeeLocks, mode: Mode) {
		self.feeSummary = feeSummary
		self.feeLocks = feeLocks
		self.mode = mode
	}

	public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
		self.init(feeSummary: feeSummary, feeLocks: feeLocks, mode: .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks)))
	}

	public init(executionAnalysis: ExecutionAnalysis, signaturesCount: Int, notaryIsSignatory: Bool, includeLockFee: Bool) throws {
		let feeSummary: FeeSummary = try .init(
			executionCost: executionAnalysis.feeSummary.executionCost.asBigDecimal(),
			finalizationCost: executionAnalysis.feeSummary.finalizationCost.asBigDecimal(),
			storageExpansionCost: executionAnalysis.feeSummary.storageExpansionCost.asBigDecimal(),
			royaltyCost: executionAnalysis.feeSummary.royaltyCost.asBigDecimal(),
			guaranteesCost: executionAnalysis.guranteesFee(),
			signaturesCost: PredefinedFeeConstants.signaturesCost(signaturesCount),
			lockFeeCost: includeLockFee ? PredefinedFeeConstants.lockFeeInstructionCost : .zero,
			notarizingCost: PredefinedFeeConstants.notarizingCost(notaryIsSignatory)
		)

		let feeLocks: FeeLocks = try .init(
			nonContingentLock: executionAnalysis.feeLocks.lock.asBigDecimal(),
			contingentLock: executionAnalysis.feeLocks.contingentLock.asBigDecimal()
		)

		self.init(
			feeSummary: feeSummary,
			feeLocks: feeLocks
		)
	}

	public mutating func updatingSignaturesCost(_ signaturesCount: Int, notaryIsSignatory: Bool) {
		var feeSummary = feeSummary
		feeSummary.signaturesCost = PredefinedFeeConstants.signaturesCost(signaturesCount)
		feeSummary.notarizingCost = PredefinedFeeConstants.notarizingCost(notaryIsSignatory)
		let mode: Mode = {
			switch self.mode {
			case .normal:
				return .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
			case .advanced:
				return .advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
			}
		}()
		self = .init(feeSummary: feeSummary, feeLocks: feeLocks, mode: mode)
	}

	public mutating func update(with feeSummaryField: WritableKeyPath<FeeSummary, BigDecimal>, amount: BigDecimal) {
		var feeSummary = feeSummary
		feeSummary[keyPath: feeSummaryField] = amount
		let mode: Mode = {
			switch self.mode {
			case .normal:
				return .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
			case .advanced:
				return .advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
			}
		}()
		self = .init(feeSummary: feeSummary, feeLocks: feeLocks, mode: mode)
	}

	public mutating func addLockFeeCost() {
		update(with: \.lockFeeCost, amount: PredefinedFeeConstants.lockFeeInstructionCost)
	}

	public mutating func updateNotarizingCost(_ notaryIsSignatory: Bool) {
		update(with: \.notarizingCost, amount: PredefinedFeeConstants.notarizingCost(notaryIsSignatory))
	}

	public mutating func updateSignaturesCost(_ count: Int) {
		update(with: \.signaturesCost, amount: PredefinedFeeConstants.signaturesCost(count))
	}
}

extension ExecutionAnalysis {
	func guranteesFee() throws -> BigDecimal {
		let transaction = try transactionTypes.transactionKind()
		switch transaction {
		case .nonConforming:
			return .zero
		case let .conforming(transaction):
			return transaction.accountDeposits.flatMap(\.value).reduce(.zero) { result, resource in
				switch resource {
				case .fungible(_, .predicted):
					return result + TransactionFee.PredefinedFeeConstants.fungibleGuaranteeInstructionCost
				default:
					return result
				}
			}
		}
	}
}

extension TransactionFee {
	/// Calculates the totalFee for the transaction based on the `mode`
	public var totalFee: TotalFee {
		switch mode {
		case let .normal(normalCustomization):
			let maxFee = normalCustomization.total
			let minFee = maxFee.clampedDiff(feeLocks.contingentLock)
			return .init(min: minFee, max: maxFee)
		case let .advanced(advancedCustomization):
			return .init(min: advancedCustomization.total, max: advancedCustomization.total)
		}
	}

	public mutating func toggleMode() {
		switch mode {
		case .normal:
			mode = .advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		case .advanced:
			mode = .normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		}
	}

	public var isNormalMode: Bool {
		if case .normal = mode {
			return true
		}
		return false
	}
}

extension TransactionFee {
	public enum PredefinedFeeConstants {
		/// 15% margin is added here to make up for the ambiguity of the transaction preview estimate)
		public static let networkFeeMultiplier: BigDecimal = 0.15

		/// Network fees -> https://radixdlt.atlassian.net/wiki/spaces/S/pages/3134783512/Manifest+Mutation+Cost+Addition+Estimates
		public static let lockFeeInstructionCost = try! BigDecimal(fromString: "0.095483092333982841")
		public static let fungibleGuaranteeInstructionCost = try! BigDecimal(fromString: "0.012001947444660947")
		public static let nonFungibleGuranteeInstructionCost = try! BigDecimal(fromString: "0.012844397444660947")
		public static let signatureCost = try! BigDecimal(fromString: "0.017839046256509498")
		public static let notarizingCost = try! BigDecimal(fromString: "0.01322565755208264")
		public static let notarizingCostWhenNotaryIsSignatory = try! BigDecimal(fromString: "0.01351365755208264")

		public static func notarizingCost(_ notaryIsSignatory: Bool) -> BigDecimal {
			notaryIsSignatory ? notarizingCostWhenNotaryIsSignatory : notarizingCost
		}

		public static func signaturesCost(_ signaturesCount: Int) -> BigDecimal {
			BigDecimal(signaturesCount) * PredefinedFeeConstants.signatureCost
		}
	}

	public enum Mode: Hashable, Sendable {
		case normal(NormalFeeCustomization)
		case advanced(AdvancedFeeCustomization)
	}

	public struct FeeSummary: Hashable, Sendable {
		public let executionCost: BigDecimal
		public let finalizationCost: BigDecimal
		public let storageExpansionCost: BigDecimal
		public let royaltyCost: BigDecimal

		public let guaranteesCost: BigDecimal

		public var lockFeeCost: BigDecimal
		public var signaturesCost: BigDecimal
		public var notarizingCost: BigDecimal

		public var totalExecutionCost: BigDecimal {
			executionCost
				+ guaranteesCost
				+ signaturesCost
				+ lockFeeCost
				+ notarizingCost
		}

		public var total: BigDecimal {
			totalExecutionCost
				+ finalizationCost
				+ storageExpansionCost
				+ royaltyCost
		}

		public init(
			executionCost: BigDecimal,
			finalizationCost: BigDecimal,
			storageExpansionCost: BigDecimal,
			royaltyCost: BigDecimal,
			guaranteesCost: BigDecimal,
			signaturesCost: BigDecimal,
			lockFeeCost: BigDecimal,
			notarizingCost: BigDecimal
		) {
			self.executionCost = executionCost
			self.finalizationCost = finalizationCost
			self.storageExpansionCost = storageExpansionCost
			self.royaltyCost = royaltyCost
			self.guaranteesCost = guaranteesCost
			self.signaturesCost = signaturesCost
			self.lockFeeCost = lockFeeCost
			self.notarizingCost = notarizingCost
		}
	}

	public struct FeeLocks: Hashable, Sendable {
		public let nonContingentLock: BigDecimal
		public let contingentLock: BigDecimal

		public init(nonContingentLock: BigDecimal, contingentLock: BigDecimal) {
			self.nonContingentLock = nonContingentLock
			self.contingentLock = contingentLock
		}
	}

	public struct AdvancedFeeCustomization: Hashable, Sendable {
		public let feeSummary: FeeSummary
		public var paddingFee: BigDecimal
		public var tipPercentage: BigDecimal
		public let paidByDapps: BigDecimal

		public var tipAmount: BigDecimal {
			(tipPercentage / 100) * (feeSummary.totalExecutionCost + feeSummary.finalizationCost)
		}

		public var total: BigDecimal {
			feeSummary.total + paddingFee + tipAmount + paidByDapps
		}

		public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
			self.feeSummary = feeSummary
			self.paddingFee = (feeSummary.totalExecutionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost) * PredefinedFeeConstants.networkFeeMultiplier
			self.tipPercentage = .zero
			var lock = feeLocks.nonContingentLock
			lock.negate()
			self.paidByDapps = lock
		}
	}

	public struct NormalFeeCustomization: Hashable, Sendable {
		public let networkFee: BigDecimal
		public let royaltyFee: BigDecimal
		public let total: BigDecimal

		public init(networkFee: BigDecimal, royaltyFee: BigDecimal) {
			self.networkFee = networkFee
			self.royaltyFee = royaltyFee
			self.total = networkFee + royaltyFee
		}

		public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
			let networkFee = (
				feeSummary.totalExecutionCost
					+ feeSummary.finalizationCost
					+ feeSummary.storageExpansionCost
			) * (1 + PredefinedFeeConstants.networkFeeMultiplier) // add network multiplier on top
			let remainingNonContingentLock = feeLocks.nonContingentLock.clampedDiff(networkFee)

			self.init(
				networkFee: networkFee.clampedDiff(feeLocks.nonContingentLock),
				royaltyFee: feeSummary.royaltyCost.clampedDiff(remainingNonContingentLock)
			)
		}
	}

	public struct TotalFee: Hashable, Sendable {
		public let min: BigDecimal
		public let max: BigDecimal

		public init(min: BigDecimal, max: BigDecimal) {
			self.min = min
			self.max = max
		}

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
