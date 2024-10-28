extension PreAuthorizationClient: DependencyKey {
	static var liveValue: Self {
		@Dependency(\.gatewaysClient) var gatewaysClient

		@Sendable
		func analysePreview(request: GetPreviewRequest) async throws -> PreAuthToReview {
			do {
				return try await SargonOS.shared.analysePreAuthPreview(
					instructions: request.unvalidatedManifest.transactionManifestString,
					blobs: request.unvalidatedManifest.blobs,
					nonce: request.nonce
				)
			} catch {
				throw PreAuthorizationFailure.failedToGetPreview(.failedToAnalyse(error))
			}
		}

		let getPreview: GetPreview = { request in
			let kind = try await analysePreview(request: request)
			let networkID = await gatewaysClient.getCurrentNetworkID()

			return PreAuthorizationToReview(
				kind: kind,
				networkID: networkID
			)
		}

		return Self(
			getPreview: getPreview
		)
	}
}
