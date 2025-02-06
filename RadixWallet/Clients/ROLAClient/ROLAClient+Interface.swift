// MARK: - ROLAClient
struct ROLAClient: Sendable, DependencyKey {
	/// verifies that the component on ledger at 'dAppDefinitionAddress' matches the metadata in the request from the dapp.
	/// it does so by fetching the metadata for dAppDefinitionAddress
	/// and asserting that the `accounType` is "dapp definition" and that its `relatedWebsites` contain the `metadata.origin`
	var performDappDefinitionVerification: PerformDappDefinitionVerification

	/// verifies that the wellknown file found at metadata.origin contains the dDappDefinitionAddress
	var performWellKnownFileCheck: PerformWellKnownFileCheck
	var manifestForAuthKeyCreation: ManifestForAuthKeyCreation
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	typealias PerformDappDefinitionVerification = @Sendable (DappToWalletInteractionMetadata) async throws -> Void
	typealias PerformWellKnownFileCheck = @Sendable (URL, DappDefinitionAddress) async throws -> Void
	typealias ManifestForAuthKeyCreation = @Sendable (ManifestForAuthKeyCreationRequest) async throws -> TransactionManifest
}

extension DependencyValues {
	var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}

// MARK: - ManifestForAuthKeyCreationRequest
struct ManifestForAuthKeyCreationRequest: Sendable, Hashable {
	let entity: AccountOrPersona
	let newPublicKey: Sargon.PublicKey

	init(
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
