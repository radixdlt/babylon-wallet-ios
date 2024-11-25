// MARK: - PreAuthorizationClient
struct PreAuthorizationClient: Sendable {
	var getPreview: GetPreview
	var buildSubintent: BuildSubintent
}

// MARK: PreAuthorizationClient.GetPreview
extension PreAuthorizationClient {
	typealias GetPreview = @Sendable (GetPreviewRequest) async throws -> PreAuthorizationPreview
	typealias BuildSubintent = @Sendable (BuildSubintentRequest) async throws -> Subintent
}

// MARK: PreAuthorizationClient.GetPreviewRequest
extension PreAuthorizationClient {
	struct GetPreviewRequest: Hashable, Sendable {
		let unvalidatedManifest: UnvalidatedSubintentManifest
		let nonce: Nonce
		let notaryPublicKey: Curve25519.Signing.PublicKey
	}

	struct BuildSubintentRequest: Sendable {
		let intentDiscriminator: IntentDiscriminator
		let manifest: SubintentManifest
		let expiration: DappToWalletInteractionSubintentExpiration
		let message: String?
	}
}
