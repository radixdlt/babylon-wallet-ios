import ClientPrelude
import Profile

// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	public var performDappDefinitionVerification: PerformDappDefinitionVerification
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var createAuthSigningKeyForAccountIfNeeded: CreateAuthSigningKeyForAccountIfNeeded
	public var createAuthSigningKeyForPersonaIfNeeded: CreateAuthSigningKeyForPersonaIfNeeded
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (P2P.Dapp.Request.Metadata) async throws -> Void
	public typealias CreateAuthSigningKeyForAccountIfNeeded = @Sendable (CreateAuthSigningKeyForAccountIfNeededRequest) async throws -> Void
	public typealias CreateAuthSigningKeyForPersonaIfNeeded = @Sendable (CreateAuthSigningKeyForPersonaIfNeededRequest) async throws -> Void
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - CreateAuthSigningKeyForAccountIfNeededRequest
public struct CreateAuthSigningKeyForAccountIfNeededRequest: Sendable, Hashable {
	public let account: Profile.Network.Account
}

// MARK: - CreateAuthSigningKeyForPersonaIfNeededRequest
public struct CreateAuthSigningKeyForPersonaIfNeededRequest: Sendable, Hashable {
	public let persona: Profile.Network.Persona
}
