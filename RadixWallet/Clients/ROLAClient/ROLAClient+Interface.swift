// MARK: - ROLAClient
struct ROLAClient: Sendable, DependencyKey {
	/// verifies that the component on ledger at 'dAppDefinitionAddress' matches the metadata in the request from the dapp.
	/// it does so by fetching the metadata for dAppDefinitionAddress
	/// and asserting that the `accounType` is "dapp definition" and that its `relatedWebsites` contain the `metadata.origin`
	var performDappDefinitionVerification: PerformDappDefinitionVerification

	/// verifies that the wellknown file found at metadata.origin contains the dDappDefinitionAddress
	var performWellKnownFileCheck: PerformWellKnownFileCheck
}

// MARK: ROLAClient.PerformWellKnownFileCheck
extension ROLAClient {
	typealias PerformDappDefinitionVerification = @Sendable (DappToWalletInteractionMetadata) async throws -> Void
	typealias PerformWellKnownFileCheck = @Sendable (URL, DappDefinitionAddress) async throws -> Void
}

extension DependencyValues {
	var rolaClient: ROLAClient {
		get { self[ROLAClient.self] }
		set { self[ROLAClient.self] = newValue }
	}
}
