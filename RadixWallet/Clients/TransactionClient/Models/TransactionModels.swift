import Sargon

// MARK: - TransactionSigners
struct TransactionSigners: Hashable {
	let notaryPublicKey: Curve25519.Signing.PublicKey
	let intentSigning: IntentSigning

	enum IntentSigning: Hashable {
		case notaryIsSignatory
		case intentSigners(NonEmpty<OrderedSet<AccountOrPersona>>)
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

		self.init(
			optIns: .init(radixEngineToolkitReceipt: true),
			manifest: rawManifest.instructionsString,
			blobsHex: rawManifest.blobs.blobs.map(\.hex),
			startEpochInclusive: .init(header.startEpochInclusive),
			endEpochExclusive: .init(header.endEpochExclusive),
			notaryPublicKey: GatewayAPI.PublicKey(from: header.notaryPublicKey),
			notaryIsSignatory: notaryIsSignatory,
			tipPercentage: .init(header.tipPercentage),
			nonce: Int64(header.nonce.value),
			signerPublicKeys: transactionSigners.signerPublicKeys.map(GatewayAPI.PublicKey.init(from:)),
			flags: flags
		)
	}
}

extension TransactionSigners {
	var notaryIsSignatory: Bool {
		switch self.intentSigning {
		case .intentSigners: false
		case .notaryIsSignatory: true
		}
	}

	var signerPublicKeys: Set<Sargon.PublicKey> {
		switch intentSigning {
		case let .intentSigners(signers):
			Set(signers.flatMap { ent in ent.virtualHierarchicalDeterministicFactorInstances.map(\.publicKey.publicKey) })
		case .notaryIsSignatory:
			[]
		}
	}

	func intentSignerEntitiesOrEmpty() -> OrderedSet<AccountOrPersona> {
		switch intentSigning {
		case .notaryIsSignatory: .init()
		case let .intentSigners(signers): OrderedSet(signers)
		}
	}
}

extension GatewayAPI.PublicKey {
	init(from sargon: Sargon.PublicKey) {
		switch sargon {
		case let .ed25519(pubKey):
			self = .eddsaEd25519(.init(keyType: .eddsaEd25519, keyHex: pubKey.hex))
		case let .secp256k1(pubKey):
			self = .ecdsaSecp256k1(.init(keyType: .ecdsaSecp256k1, keyHex: pubKey.hex))
		}
	}
}

// MARK: - NotarizeTransactionRequest
struct NotarizeTransactionRequest: Hashable {
	let intentSignatures: Set<SignatureWithPublicKey>
	let transactionIntent: TransactionIntent
	let notary: Curve25519.Signing.PrivateKey
}

// MARK: - NotarizeTransactionResponse
struct NotarizeTransactionResponse: Hashable {
	let notarized: NotarizedTransaction
	let intent: TransactionIntent
	let txID: TransactionIntentHash
}

// MARK: - BuildTransactionIntentRequest
struct BuildTransactionIntentRequest {
	let networkID: NetworkID
	let nonce: Nonce
	let manifest: TransactionManifest
	let message: Message
	let makeTransactionHeaderInput: MakeTransactionHeaderInput
	let transactionSigners: TransactionSigners

	init(
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
struct GetTransactionSignersRequest: Hashable {
	let networkID: NetworkID
	let executionSummary: ExecutionSummary
	let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
}

// MARK: - ManifestReviewRequest
struct ManifestReviewRequest {
	let unvalidatedManifest: UnvalidatedTransactionManifest
	let message: Message
	let nonce: Nonce
	let makeTransactionHeaderInput: MakeTransactionHeaderInput
	let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
	let signingPurpose: SigningPurpose
	let isWalletTransaction: Bool

	init(
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
struct FeePayerCandidate: Hashable, Identifiable {
	typealias ID = Account.ID
	var id: ID {
		account.id
	}

	let account: Account
	let xrdBalance: Decimal192
}

// MARK: - TransactionToReview
struct TransactionToReview: Hashable {
	let transactionManifest: TransactionManifest
	let analyzedManifestToReview: ExecutionSummary
	let networkID: NetworkID

	var transactionFee: TransactionFee
	var transactionSigners: TransactionSigners
	var signingFactors: SigningFactors
}

// MARK: - FeePayerSelectionAmongstCandidates
struct FeePayerSelectionAmongstCandidates: Hashable {
	var selected: FeePayerCandidate?
	/// contains `selected`
	let candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
	var transactionFee: TransactionFee
}

// MARK: - DetermineFeePayerRequest
struct DetermineFeePayerRequest {
	let networkId: NetworkID
	let transactionFee: TransactionFee
	let transactionSigners: TransactionSigners
	let signingFactors: SigningFactors
	let signingPurpose: SigningPurpose
	let executionSummary: ExecutionSummary
}

// MARK: - DetermineFeePayerResponse
struct DetermineFeePayerResponse {
	/// The result of selecting a fee payer among the below candidates list
	let feePayerSelection: FeePayerSelectionResult?
	/// The list of all the possible fee payer candidates
	let candidates: NonEmpty<IdentifiedArrayOf<FeePayerCandidate>>
}

// MARK: - FeePayerSelectionResult
/// The result of selecting a fee payer.
/// In the case when the fee payer is not an account for which we do already have the signature - the fee, transactionSigners and signingFactors will be updated
/// to account for the new signature that is required to be added
struct FeePayerSelectionResult: Equatable {
	let payer: FeePayerCandidate
	let updatedFee: TransactionFee
	let transactionSigners: TransactionSigners
	let signingFactors: SigningFactors
}

extension ExecutionSummary {
	func guranteesCost() throws -> Decimal192 {
		switch detailedClassification {
		case .general, .transfer:
			deposits.flatMap(\.value).reduce(.zero) { result, resource in
				switch resource {
				case let .fungible:
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
