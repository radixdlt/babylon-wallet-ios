import ClientPrelude
import Cryptography
import EngineKit
import FactorSourcesClient

// MARK: - TransactionClient
public struct TransactionClient: Sendable, DependencyKey {
	public var getTransactionReview: GetTransactionReview
	public var buildTransactionIntent: BuildTransactionIntent
	public var notarizeTransaction: NotarizeTransaction
	public var prepareForSigning: PrepareForSigning
	public var myInvolvedEntities: MyInvolvedEntities
}

// MARK: TransactionClient.SignAndSubmitTransaction
extension TransactionClient {
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

extension TransactionClient {
	public struct PrepareForSigningRequest: Equatable, Sendable {
		public let nonce: Nonce
		public let manifest: TransactionManifest
		public let message: Message
		// Optional, as there might not be any fee
		public let feePayer: Profile.Network.Account?
		public let networkID: NetworkID
		public let purpose: SigningPurpose

		public var compiledIntent: [UInt8]? = nil
		public let ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey
		public let transactionHeader: MakeTransactionHeaderInput

		public init(
			nonce: Nonce,
			manifest: TransactionManifest,
			message: Message,
			networkID: NetworkID,
			feePayer: Profile.Network.Account?,
			purpose: SigningPurpose,
			ephemeralNotaryPublicKey: Curve25519.Signing.PublicKey,
			transactionHeader: MakeTransactionHeaderInput
		) {
			self.nonce = nonce
			self.manifest = manifest
			self.message = message
			self.networkID = networkID
			self.feePayer = feePayer
			self.purpose = purpose
			self.ephemeralNotaryPublicKey = ephemeralNotaryPublicKey
			self.transactionHeader = transactionHeader
		}
	}

	public struct PrepareForSiginingResponse: Equatable, Sendable {
		public let intent: TransactionIntent
		public let signingFactors: SigningFactors

		public init(intent: TransactionIntent, signingFactors: SigningFactors) {
			self.intent = intent
			self.signingFactors = signingFactors
		}
	}
}
