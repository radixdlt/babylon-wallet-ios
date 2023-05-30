import AsyncExtensions
import ClientPrelude
import CryptoKit
import FactorSourcesClient
import SharedModels

// MARK: - DappInteractionClient
public struct DappInteractionClient: Sendable {
	public let interactions: AnyAsyncSequence<ValidatedDappRequest>
	public let addWalletInteraction: AddWalletInteraction
	public let completeInteraction: CompleteInteraction
	public let prepareFoSigning: PrepareFoSigning

	public init(
		interactions: AnyAsyncSequence<ValidatedDappRequest>,
		addWalletInteraction: @escaping AddWalletInteraction,
		completeInteraction: @escaping CompleteInteraction,
		prepareFoSigning: @escaping PrepareFoSigning
	) {
		self.interactions = interactions
		self.addWalletInteraction = addWalletInteraction
		self.completeInteraction = completeInteraction
		self.prepareFoSigning = prepareFoSigning
	}
}

extension DappInteractionClient {
	public typealias AddWalletInteraction = @Sendable (P2P.Dapp.Request.Items) -> Void
	public typealias CompleteInteraction = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
	public typealias PrepareFoSigning = @Sendable (PrepareForSigningRequest) async throws -> PrepareForSiginingResponse
}

extension DappInteractionClient {
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

extension DappInteractionClient {
	public struct RequestEnvelope: Sendable, Hashable {
		public let route: P2P.Route
		public let request: P2P.Dapp.Request

		public init(route: P2P.Route, request: P2P.Dapp.Request) {
			self.route = route
			self.request = request
		}
	}

	public enum ValidatedDappRequest: Sendable, Hashable {
		case valid(RequestEnvelope)
		case invalid(Invalid)

		public enum Invalid: Sendable, Hashable {
			case incompatibleVersion(connectorExtensionSent: P2P.Dapp.Version, walletUses: P2P.Dapp.Version)
			case wrongNetworkID(connectorExtensionSent: NetworkID, walletUses: NetworkID)
			case invalidDappDefinitionAddress(gotStringWhichIsAnInvalidAccountAddress: String)
			case invalidOrigin(invalidURLString: String)
			case badContent(BadContent)
			case p2pError(String)
			public enum BadContent: Sendable, Hashable {
				case numberOfAccountsInvalid
			}
		}
	}
}
