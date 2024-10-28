// MARK: - PreAuthorizationClient
struct PreAuthorizationClient: Sendable {
	var getPreview: GetPreview
}

// MARK: PreAuthorizationClient.GetPreview
extension PreAuthorizationClient {
	typealias GetPreview = @Sendable (GetPreviewRequest) async throws -> PreAuthorizationToReview
}

// MARK: PreAuthorizationClient.GetPreviewRequest
extension PreAuthorizationClient {
	struct GetPreviewRequest: Hashable, Sendable {
		let unvalidatedManifest: UnvalidatedTransactionManifest
		let nonce: Nonce
	}
}
