import ClientPrelude
import Cryptography
import Profile
import SharedModels

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var manifestForAuthKeyCreation: ManifestForAuthKeyCreation
	public var authenticationDataToSignForChallenge: AuthenticationDataToSignForChallenge
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias ManifestForAuthKeyCreation = @Sendable (ManifestForAuthKeyCreationRequest) async throws -> ManifestForAuthKeyCreationResponse
	public typealias AuthenticationDataToSignForChallenge = @Sendable (AuthenticationDataToSignForChallengeRequest) throws -> AuthenticationDataToSignForChallengeResponse
}

// MARK: - ManifestForAuthKeyCreationResponse
public struct ManifestForAuthKeyCreationResponse: Sendable, Hashable {
	public let manifest: TransactionManifest
	public let authenticationSigning: FactorInstance
}

// MARK: - AuthenticationDataToSignForChallengeResponse
public struct AuthenticationDataToSignForChallengeResponse: Sendable, Hashable {
	public let input: AuthenticationDataToSignForChallengeRequest
	public let payloadToHashAndSign: Data

	public init(
		input: AuthenticationDataToSignForChallengeRequest,
		payloadToHashAndSign: Data
	) {
		self.input = input
		self.payloadToHashAndSign = payloadToHashAndSign
	}
}

// MARK: - AuthenticationDataToSignForChallengeRequest
public struct AuthenticationDataToSignForChallengeRequest: Sendable, Hashable {
	public let challenge: P2P.Dapp.Request.AuthChallengeNonce
	public let origin: P2P.Dapp.Request.Metadata.Origin
	public let dAppDefinitionAddress: DappDefinitionAddress

	public init(
		challenge: P2P.Dapp.Request.AuthChallengeNonce,
		origin: P2P.Dapp.Request.Metadata.Origin,
		dAppDefinitionAddress: DappDefinitionAddress
	) {
		self.challenge = challenge
		self.origin = origin
		self.dAppDefinitionAddress = dAppDefinitionAddress
	}
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
