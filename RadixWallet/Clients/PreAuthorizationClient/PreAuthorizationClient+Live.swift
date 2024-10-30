extension PreAuthorizationClient: DependencyKey {
	static var liveValue: Self {
		@Dependency(\.gatewaysClient) var gatewaysClient

		@Sendable
		func analysePreview(request: GetPreviewRequest) async throws -> PreAuthToReview {
			do {
				return try await SargonOS.shared.analysePreAuthPreview(
					instructions: request.unvalidatedManifest.subintentManifestString,
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

			return PreAuthorizationPreview(
				kind: kind,
				networkId: networkID,
				signingFactors: [:] // TODO: Implement!
			)
		}

		let buildSubintent: BuildSubintent = { _ in
			fatalError("implement")
		}

		return Self(
			getPreview: getPreview,
			buildSubintent: buildSubintent
		)
	}
}
