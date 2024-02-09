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
	init(from engine: RETPublicKey) {
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
	public let intentSignatures: Set<RETSignatureWithPublicKey>
	public let transactionIntent: TransactionIntent
	public let notary: SLIP10.PrivateKey
	public init(
		intentSignatures: Set<RETSignatureWithPublicKey>,
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
	public let notarized: Data
	public let intent: TransactionIntent
	public let txID: TXID
	public init(notarized: Data, intent: TransactionIntent, txID: TXID) {
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
	public let unvalidatedManifest: UnvalidatedTransactionManifest
	public let message: Message
	public let nonce: Nonce
	public let makeTransactionHeaderInput: MakeTransactionHeaderInput
	public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
	public let signingPurpose: SigningPurpose
	public let isWalletTransaction: Bool

	public init(
		unvalidatedManifest: UnvalidatedTransactionManifest,
		message: Message,
		nonce: Nonce,
		makeTransactionHeaderInput: MakeTransactionHeaderInput = .default,
		ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey,
		signingPurpose: SigningPurpose,
		isWalletTransaction: Bool
	) {
		self.unvalidatedManifest = unvalidatedManifest
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
	public let transactionManifest: TransactionManifest
	public let analyzedManifestToReview: ExecutionSummary
	public let networkID: NetworkID

	public var transactionFee: TransactionFee
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

// MARK: - DetermineFeePayerRequest
public struct DetermineFeePayerRequest: Sendable {
	let networkId: NetworkID
	let transactionFee: TransactionFee
	let transactionSigners: TransactionSigners
	let signingFactors: SigningFactors
	let signingPurpose: SigningPurpose
	let manifest: TransactionManifest
}

// MARK: - DetermineFeePayerResponse
public struct DetermineFeePayerResponse: Sendable {
	/// The result of selecting a fee payer among the below candidates list
	public let feePayerSelection: FeePayerSelectionResult?
	/// The list of all the possible fee payer candidates
	public let candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
}

// MARK: - FeePayerSelectionResult
/// The result of selecting a fee payer.
/// In the case when the fee payer is not an account for which we do already have the signature - the fee, transactionSigners and signingFactors will be updated
/// to account for the new signature that is required to be added
public struct FeePayerSelectionResult: Equatable, Sendable {
	public let payer: FeePayerCandidate
	public let updatedFee: TransactionFee
	public let transactionSigners: TransactionSigners
	public let signingFactors: SigningFactors

	public init(
		payer: FeePayerCandidate,
		updatedFee: TransactionFee,
		transactionSigners: TransactionSigners,
		signingFactors: SigningFactors
	) {
		self.payer = payer
		self.updatedFee = updatedFee
		self.transactionSigners = transactionSigners
		self.signingFactors = signingFactors
	}
}

extension ExecutionSummary {
	func guranteesCost() throws -> RETDecimal {
		switch detailedManifestClass {
		case .general, .transfer:
			accountDeposits.flatMap(\.value).reduce(.zero) { result, resource in
				switch resource {
				case .fungible(_, .predicted):
					result + TransactionFee.PredefinedFeeConstants.fungibleGuaranteeInstructionCost
				default:
					result
				}
			}
		default:
			.zero
		}
	}
}
