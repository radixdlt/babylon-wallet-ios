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
		case .intentSigners: false
		case .notaryIsSignatory: true
		}
	}

	public var signerPublicKeys: Set<SLIP10.PublicKey> {
		switch intentSigning {
		case let .intentSigners(signers):
			Set(signers.flatMap { $0.virtualHierarchicalDeterministicFactorInstances.map(\.publicKey) })
		case .notaryIsSignatory:
			[]
		}
	}

	public func intentSignerEntitiesOrEmpty() -> OrderedSet<EntityPotentiallyVirtual> {
		switch intentSigning {
		case .notaryIsSignatory: .init()
		case let .intentSigners(signers): OrderedSet(signers)
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
	public let intent: TransactionIntent
	public let txID: TXID
	public init(notarized: [UInt8], intent: TransactionIntent, txID: TXID) {
		self.notarized = notarized
		self.intent = intent
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
		public var amount: RETDecimal
		public var instructionIndex: UInt64
		public var resourceAddress: ResourceAddress
		public var resourceDivisibility: Int?

		public init(
			amount: RETDecimal,
			instructionIndex: UInt64,
			resourceAddress: ResourceAddress,
			resourceDivisibility: Int?
		) {
			self.amount = amount
			self.instructionIndex = instructionIndex
			self.resourceAddress = resourceAddress
			self.resourceDivisibility = resourceDivisibility
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
	public let signingPurpose: SigningPurpose
	public let isWalletTransaction: Bool

	public init(
		manifestToSign: TransactionManifest,
		message: Message,
		nonce: Nonce,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey,
		signingPurpose: SigningPurpose,
		isWalletTransaction: Bool
	) {
		self.manifestToSign = manifestToSign
		self.message = message
		self.nonce = nonce
		self.makeTransactionHeaderInput = makeTransactionHeaderInput
		self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
		self.signingPurpose = signingPurpose
		self.isWalletTransaction = isWalletTransaction
	}
}

// MARK: - FeePayerCandidate
public struct FeePayerCandidate: Sendable, Hashable, Identifiable {
	public typealias ID = Profile.Network.Account.ID
	public var id: ID { account.id }

	public let account: Profile.Network.Account
	public let xrdBalance: RETDecimal

	public init(account: Profile.Network.Account, xrdBalance: RETDecimal) {
		self.account = account
		self.xrdBalance = xrdBalance
	}
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

	public init(
		executionAnalysis: ExecutionAnalysis,
		signaturesCount: Int,
		notaryIsSignatory: Bool,
		includeLockFee: Bool
	) throws {
		let feeSummary: FeeSummary = try .init(
			executionCost: executionAnalysis.feeSummary.executionCost,
			finalizationCost: executionAnalysis.feeSummary.finalizationCost,
			storageExpansionCost: executionAnalysis.feeSummary.storageExpansionCost,
			royaltyCost: executionAnalysis.feeSummary.royaltyCost,
			guaranteesCost: executionAnalysis.guranteesCost(),
			signaturesCost: PredefinedFeeConstants.signaturesCost(signaturesCount),
			lockFeeCost: includeLockFee ? PredefinedFeeConstants.lockFeeInstructionCost : .zero,
			notarizingCost: PredefinedFeeConstants.notarizingCost(notaryIsSignatory)
		)

		let feeLocks: FeeLocks = .init(
			nonContingentLock: executionAnalysis.feeLocks.lock,
			contingentLock: executionAnalysis.feeLocks.contingentLock
		)

		self.init(
			feeSummary: feeSummary,
			feeLocks: feeLocks
		)
	}

	public mutating func update(with feeSummaryField: WritableKeyPath<FeeSummary, RETDecimal>, amount: RETDecimal) {
		var feeSummary = feeSummary
		feeSummary[keyPath: feeSummaryField] = amount
		let mode: Mode = switch self.mode {
		case .normal:
			.normal(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		case .advanced:
			.advanced(.init(feeSummary: feeSummary, feeLocks: feeLocks))
		}
		self = .init(feeSummary: feeSummary, feeLocks: feeLocks, mode: mode)
	}

	public mutating func addLockFeeCost() {
		update(with: \.lockFeeCost, amount: PredefinedFeeConstants.lockFeeInstructionCost)
	}

	public mutating func updateNotarizingCost(notaryIsSignatory: Bool) {
		update(with: \.notarizingCost, amount: PredefinedFeeConstants.notarizingCost(notaryIsSignatory))
	}

	public mutating func updateSignaturesCost(_ count: Int) {
		update(with: \.signaturesCost, amount: PredefinedFeeConstants.signaturesCost(count))
	}
}

extension ExecutionAnalysis {
	func guranteesCost() throws -> RETDecimal {
		let transaction = try transactionTypes.transactionKind()
		switch transaction {
		case .nonConforming:
			return .zero
		case let .conforming(.general(transaction)):
			return transaction.accountDeposits.flatMap(\.value).reduce(.zero) { result, resource in
				switch resource {
				case .fungible(_, .predicted):
					result + TransactionFee.PredefinedFeeConstants.fungibleGuaranteeInstructionCost
				default:
					result
				}
			}
		case .conforming:
			return .zero
		}
	}
}

extension TransactionFee {
	/// Calculates the totalFee for the transaction based on the `mode`
	public var totalFee: TotalFee {
		switch mode {
		case let .normal(normalCustomization):
			let maxFee = normalCustomization.total
			let minFee = (maxFee - feeLocks.contingentLock).clamped
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
		public static let networkFeeMultiplier: RETDecimal = 0.15

		/// Network fees -> https://radixdlt.atlassian.net/wiki/spaces/S/pages/3134783512/Manifest+Mutation+Cost+Addition+Estimates
		// swiftformat:disable all
		public static let lockFeeInstructionCost =              try! RETDecimal(value: "0.08581566997")
		public static let fungibleGuaranteeInstructionCost =    try! RETDecimal(value: "0.00908532837")
		public static let nonFungibleGuranteeInstructionCost =  try! RETDecimal(value: "0.00954602837")
		public static let signatureCost =                       try! RETDecimal(value: "0.01109974758")
		public static let notarizingCost =                      try! RETDecimal(value: "0.0081393944")
		public static let notarizingCostWhenNotaryIsSignatory = try! RETDecimal(value: "0.0084273944")
		//	swiftformat:enable all

		public static func notarizingCost(_ notaryIsSignatory: Bool) -> RETDecimal {
			notaryIsSignatory ? notarizingCostWhenNotaryIsSignatory : notarizingCost
		}

		public static func signaturesCost(_ signaturesCount: Int) -> RETDecimal {
			RETDecimal(integer: signaturesCount) * PredefinedFeeConstants.signatureCost
		}
	}

	public enum Mode: Hashable, Sendable {
		case normal(NormalFeeCustomization)
		case advanced(AdvancedFeeCustomization)
	}

	public struct FeeSummary: Hashable, Sendable {
		public let executionCost: RETDecimal
		public let finalizationCost: RETDecimal
		public let storageExpansionCost: RETDecimal
		public let royaltyCost: RETDecimal

		public let guaranteesCost: RETDecimal

		public var lockFeeCost: RETDecimal
		public var signaturesCost: RETDecimal
		public var notarizingCost: RETDecimal

		public var totalExecutionCost: RETDecimal {
			executionCost
				+ guaranteesCost
				+ signaturesCost
				+ lockFeeCost
				+ notarizingCost
		}

		public var total: RETDecimal {
			totalExecutionCost
				+ finalizationCost
				+ storageExpansionCost
				+ royaltyCost
		}

		public init(
			executionCost: RETDecimal,
			finalizationCost: RETDecimal,
			storageExpansionCost: RETDecimal,
			royaltyCost: RETDecimal,
			guaranteesCost: RETDecimal,
			signaturesCost: RETDecimal,
			lockFeeCost: RETDecimal,
			notarizingCost: RETDecimal
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
		public let nonContingentLock: RETDecimal
		public let contingentLock: RETDecimal

		public init(nonContingentLock: RETDecimal, contingentLock: RETDecimal) {
			self.nonContingentLock = nonContingentLock
			self.contingentLock = contingentLock
		}
	}

	public struct AdvancedFeeCustomization: Hashable, Sendable {
		public let feeSummary: FeeSummary
		public var paddingFee: RETDecimal
		public var tipPercentage: UInt16
		public let paidByDapps: RETDecimal

		public var tipAmount: RETDecimal {
			(RETDecimal(integer: Int(tipPercentage)) / 100) * (feeSummary.totalExecutionCost + feeSummary.finalizationCost)
		}

		public var total: RETDecimal {
			(feeSummary.total + paddingFee + tipAmount + paidByDapps).clamped
		}

		public init(feeSummary: FeeSummary, feeLocks: FeeLocks) {
			self.feeSummary = feeSummary
			self.paddingFee = (feeSummary.totalExecutionCost + feeSummary.finalizationCost + feeSummary.storageExpansionCost) * PredefinedFeeConstants.networkFeeMultiplier
			self.tipPercentage = .zero

			/// NonContingent lock will pay for some of the fee.
			self.paidByDapps = -feeLocks.nonContingentLock
		}
	}

	public struct NormalFeeCustomization: Hashable, Sendable {
		public let networkFee: RETDecimal
		public let royaltyFee: RETDecimal
		public let total: RETDecimal

		public init(networkFee: RETDecimal, royaltyFee: RETDecimal) {
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
			let remainingNonContingentLock = (feeLocks.nonContingentLock - networkFee).clamped

			self.init(
				networkFee: (networkFee - feeLocks.nonContingentLock).clamped,
				royaltyFee: (feeSummary.royaltyCost - remainingNonContingentLock).clamped
			)
		}
	}

	public struct TotalFee: Hashable, Sendable {
		public let min: RETDecimal
		public let max: RETDecimal

		public init(min: RETDecimal, max: RETDecimal) {
			self.min = min
			self.max = max
		}

		public var lockFee: RETDecimal {
			// We always lock the max amount
			max
		}

		public var displayedTotalFee: String {
			if max > min {
				return "\(min.formatted()) - \(max.formatted()) XRD"
			}
			return "\(max.formatted()) XRD"
		}
	}
}

extension TransactionFee {
	#if DEBUG
	public static var testValue: Self {
		let feeSummary = TransactionFee.FeeSummary(
			executionCost: 5,
			finalizationCost: 5,
			storageExpansionCost: 5,
			royaltyCost: 10,
			guaranteesCost: 5,
			signaturesCost: 5,
			lockFeeCost: 5,
			notarizingCost: 5
		)
		return .init(feeSummary: feeSummary, feeLocks: .init(nonContingentLock: 0, contingentLock: 0))
	}

	public static var nonContingentLockPaying: Self {
		let feeSummary = TransactionFee.FeeSummary(
			executionCost: 5,
			finalizationCost: 5,
			storageExpansionCost: 5,
			royaltyCost: 10,
			guaranteesCost: 5,
			signaturesCost: 5,
			lockFeeCost: 5,
			notarizingCost: 5
		)
		return .init(feeSummary: feeSummary, feeLocks: .init(nonContingentLock: 100, contingentLock: 0))
	}
	#endif
}
