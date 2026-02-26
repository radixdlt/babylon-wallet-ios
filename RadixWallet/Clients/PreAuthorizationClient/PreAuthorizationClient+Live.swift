// MARK: - PreAuthorizationClient + DependencyKey
extension PreAuthorizationClient: DependencyKey {
	static var liveValue: Self {
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient

		@Sendable
		func analysePreview(request: GetPreviewRequest) async throws -> PreAuthToReview {
			do {
				return try await SargonOS.shared.analysePreAuthPreview(
					instructions: request.unvalidatedManifest.subintentManifestString,
					blobs: request.unvalidatedManifest.blobs,
					nonce: request.nonce,
					notaryPublicKey: Sargon.PublicKey.ed25519(request.notaryPublicKey.intoSargon())
				)
			} catch {
				throw TransactionFailure.fromCommonError(error as? CommonError)
			}
		}

		let getPreview: GetPreview = { request in
			let preAuthToReview = try await analysePreview(request: request)
			let networkId = await gatewaysClient.getCurrentNetworkID()

			return PreAuthorizationPreview(
				kind: preAuthToReview,
				networkId: networkId
			)
		}

		let buildSubintent: BuildSubintent = { request in
			try await SargonOS.shared.createSubintent(
				intentDiscriminator: request.intentDiscriminator,
				subintentManifest: request.manifest,
				expiration: request.expiration,
				message: request.message,
				header: request.header
			)
		}

		let pollStatus: PollStatus = { request in
			try await SargonOS.shared.pollPreAuthorizationStatus(intentHash: request.subintentHash, expirationTimestamp: request.expirationTimestamp)
		}

		return Self(
			getPreview: getPreview,
			buildSubintent: buildSubintent,
			pollStatus: pollStatus
		)
	}
}
