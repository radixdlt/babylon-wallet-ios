import ClientPrelude
import Profile

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var createAuthSigningKeyForAccountIfNeeded: CreateAuthSigningKeyForAccountIfNeeded
	public var createAuthSigningKeyForPersonaIfNeeded: CreateAuthSigningKeyForPersonaIfNeeded
	public var signAuthChallenge: SignAuthChallenge
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias CreateAuthSigningKeyForAccountIfNeeded = @Sendable (CreateAuthSigningKeyForAccountIfNeededRequest) async throws -> TransactionManifest
	public typealias CreateAuthSigningKeyForPersonaIfNeeded = @Sendable (CreateAuthSigningKeyForPersonaIfNeededRequest) async throws -> TransactionManifest
	public typealias SignAuthChallenge = @Sendable (SignAuthChallengeRequest) async throws -> SignedAuthChallenge
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - CreateAuthSigningKeyForAccountIfNeededRequest
public struct CreateAuthSigningKeyForAccountIfNeededRequest: Sendable, Hashable {
	public let accountAddress: AccountAddress
	public init(accountAddress: AccountAddress) {
		self.accountAddress = accountAddress
	}
}

// MARK: - CreateAuthSigningKeyForPersonaIfNeededRequest
public struct CreateAuthSigningKeyForPersonaIfNeededRequest: Sendable, Hashable {
	public let identityAddress: IdentityAddress
	public init(identityAddress: IdentityAddress) {
		self.identityAddress = identityAddress
	}
}

import Cryptography
import DeviceFactorSourceClient
import SharedModels

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
}

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: P2P.Dapp.AuthChallengeNonce
	public let signatureWithPublicKey: SignatureWithPublicKey
}
