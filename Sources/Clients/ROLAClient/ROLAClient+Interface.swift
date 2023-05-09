import ClientPrelude
import Cryptography
import Profile
import SharedModels

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var manifestForAuthKeyCreation: ManifestForAuthKeyCreation
	public var signAuthChallenge: SignAuthChallenge
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias ManifestForAuthKeyCreation = @Sendable (ManifestForAuthKeyCreationRequest) async throws -> ManifestForAuthKeyCreationResponse
	public typealias SignAuthChallenge = @Sendable (SignAuthChallengeRequest) async throws -> SignedAuthChallenge
}

// MARK: - ManifestForAuthKeyCreationResponse
public struct ManifestForAuthKeyCreationResponse: Sendable, Hashable {
	public let manifest: TransactionManifest
	public let authenticationSigning: FactorInstance
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - ManifestForAuthKeyCreationRequest
public struct ManifestForAuthKeyCreationRequest: Sendable, Hashable {
	public let entity: EntityPotentiallyVirtual
	public init(entity: EntityPotentiallyVirtual) throws {
		guard !entity.hasAuthenticationSigningKey else {
			throw EntityHasAuthSigningKeyAlready()
		}
		self.entity = entity
	}
}

// MARK: - EntityHasAuthSigningKeyAlready
struct EntityHasAuthSigningKeyAlready: Swift.Error {}

// MARK: - SignAuthChallengeRequest
public struct SignAuthChallengeRequest: Sendable, Hashable {
	public let challenge: P2P.Dapp.AuthChallengeNonce
	public let origin: P2P.Dapp.Request.Metadata.Origin
	public let dAppDefinitionAddress: DappDefinitionAddress
	public let persona: Profile.Network.Persona

	public init(
		challenge: P2P.Dapp.AuthChallengeNonce,
		origin: P2P.Dapp.Request.Metadata.Origin,
		dAppDefinitionAddress: DappDefinitionAddress,
		persona: Profile.Network.Persona
	) {
		self.challenge = challenge
		self.origin = origin
		self.dAppDefinitionAddress = dAppDefinitionAddress
		self.persona = persona
	}

	public init(
		challenge: P2P.Dapp.AuthChallengeNonce,
		origin: P2P.Dapp.Request.Metadata.Origin,
		dAppDefinitionAddress: AccountAddress,
		persona: Profile.Network.Persona
	) {
		self.init(challenge: challenge, origin: origin, dAppDefinitionAddress: .valid(dAppDefinitionAddress), persona: persona)
	}
}

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: P2P.Dapp.AuthChallengeNonce
	public let signatureWithPublicKey: SignatureWithPublicKey
}
