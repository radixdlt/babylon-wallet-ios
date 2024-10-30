extension PreAuthorizationClient: DependencyKey {
	static var liveValue: Self {
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.entitiesInvolvedClient) var entitiesInvolvedClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

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

		@Sendable
		func getSigningFactors(networkId: NetworkID, preAuthToReview: PreAuthToReview) async throws -> SigningFactors {
			let entitiesInvolved = try await entitiesInvolvedClient.getEntities(.init(
				networkId: networkId,
				dataSource: preAuthToReview
			))
			guard let signers = NonEmpty<Set<AccountOrPersona>>(entitiesInvolved.entitiesRequiringAuth) else {
				return [:]
			}
			return try await factorSourcesClient.getSigningFactors(.init(networkID: networkId, signers: signers, signingPurpose: .signPreAuthorization))
		}

		let getPreview: GetPreview = { request in
			let preAuthToReview = try await analysePreview(request: request)
			let networkID = await gatewaysClient.getCurrentNetworkID()
			let signingFactors = try await getSigningFactors(networkId: networkID, preAuthToReview: preAuthToReview)

			return PreAuthorizationPreview(
				kind: preAuthToReview,
				networkId: networkID,
				signingFactors: signingFactors
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
