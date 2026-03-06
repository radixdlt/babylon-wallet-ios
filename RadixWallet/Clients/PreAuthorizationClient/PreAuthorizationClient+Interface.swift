// MARK: - PreAuthorizationClient
struct PreAuthorizationClient {
	var getPreview: GetPreview
	var buildSubintent: BuildSubintent
	var pollStatus: PollStatus
}

// MARK: PreAuthorizationClient.GetPreview
extension PreAuthorizationClient {
	typealias GetPreview = @Sendable (GetPreviewRequest) async throws -> PreAuthorizationPreview
	typealias BuildSubintent = @Sendable (BuildSubintentRequest) async throws -> Subintent
	typealias PollStatus = @Sendable (PollStatusRequest) async throws -> PreAuthorizationStatus
}

// MARK: PreAuthorizationClient.GetPreviewRequest
extension PreAuthorizationClient {
	struct GetPreviewRequest: Hashable {
		let unvalidatedManifest: UnvalidatedSubintentManifest
		let nonce: Nonce
		let notaryPublicKey: Curve25519.Signing.PublicKey
	}

	struct BuildSubintentRequest {
		let intentDiscriminator: IntentDiscriminator
		let manifest: SubintentManifest
		let expiration: DappToWalletInteractionSubintentExpiration
		let message: String?
		let header: DappToWalletInteractionSubintentHeader?
	}

	struct PollStatusRequest {
		let subintentHash: SubintentHash
		let expirationTimestamp: Instant
	}
}
