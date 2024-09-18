// MARK: - ROLAClient
public struct ROLAClient: Sendable, DependencyKey {
	/// verifies that the component on ledger at 'dAppDefinitionAddress' matches the metadata in the request from the dapp.
	/// it does so by fetching the metadata for dAppDefinitionAddress
	/// and asserting that the `accounType` is "dapp definition" and that its `relatedWebsites` contain the `metadata.origin`
	public var performDappDefinitionVerification: PerformDappDefinitionVerification

	/// verifies that the wellknown file found at metadata.origin contains the dDappDefinitionAddress
	public var performWellKnownFileCheck: PerformWellKnownFileCheck
	public var manifestForAuthKeyCreation: ManifestForAuthKeyCreation
	public var authenticationDataToSignForChallenge: AuthenticationDataToSignForChallenge
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	public typealias PerformDappDefinitionVerification = @Sendable (DappToWalletInteractionMetadata) async throws -> Void
	public typealias PerformWellKnownFileCheck = @Sendable (URL, DappDefinitionAddress) async throws -> Void
	public typealias ManifestForAuthKeyCreation = @Sendable (ManifestForAuthKeyCreationRequest) async throws -> TransactionManifest
	public typealias AuthenticationDataToSignForChallenge = @Sendable (AuthenticationDataToSignForChallengeRequest) throws -> AuthenticationDataToSignForChallengeResponse
}

extension DependencyValues {
	public var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - AuthenticationDataToSignForChallengeRequest
public struct AuthenticationDataToSignForChallengeRequest: Sendable, Hashable {
	public let challenge: DappToWalletInteractionAuthChallengeNonce
	public let origin: DappOrigin
	public let dAppDefinitionAddress: DappDefinitionAddress

	public init(
		challenge: DappToWalletInteractionAuthChallengeNonce,
		origin: DappOrigin,
		dAppDefinitionAddress: DappDefinitionAddress
	) {
		self.challenge = challenge
		self.origin = origin
		self.dAppDefinitionAddress = dAppDefinitionAddress
	}
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

// MARK: - ManifestForAuthKeyCreationRequest
public struct ManifestForAuthKeyCreationRequest: Sendable, Hashable {
	public let entity: AccountOrPersona
	public let newPublicKey: Sargon.PublicKey

	public init(
		entity: AccountOrPersona,
		newPublicKey: Sargon.PublicKey
	) throws {
		guard !entity.hasAuthenticationSigningKey else {
			throw EntityHasAuthSigningKeyAlready()
		}
		self.entity = entity
		self.newPublicKey = newPublicKey
	}
}

// MARK: - EntityHasAuthSigningKeyAlready
struct EntityHasAuthSigningKeyAlready: Swift.Error {}
