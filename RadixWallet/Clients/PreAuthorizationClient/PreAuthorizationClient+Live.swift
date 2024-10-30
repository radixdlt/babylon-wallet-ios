// MARK: - PreAuthorizationClient + DependencyKey
extension PreAuthorizationClient: DependencyKey {
	static let epochWindow: Epoch = 10

	static var liveValue: Self {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
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
					nonce: request.nonce
				)
			} catch {
				throw PreAuthorizationFailure.failedToGetPreview(.failedToAnalyse(error))
			}
		}

		@Sendable
		func getSigningFactors(networkId: NetworkID, preAuthToReview: PreAuthToReview) async throws -> SigningFactors {
			let allAccounts = try await accountsClient.getAccountsOnNetwork(networkId)

			func accountFromComponentAddress(_ accountAddress: AccountAddress) -> Account? {
				allAccounts.first { $0.address == accountAddress }
			}
			func identityFromComponentAddress(_ identityAddress: IdentityAddress) async throws -> Persona {
				try await personasClient.getPersona(id: identityAddress)
			}
			func mapAccount(_ addresses: [AccountAddress]) throws -> OrderedSet<Account> {
				try .init(validating: addresses.compactMap(accountFromComponentAddress))
			}
			func mapIdentity(_ addresses: [IdentityAddress]) async throws -> OrderedSet<Persona> {
				try await .init(validating: addresses.asyncMap(identityFromComponentAddress))
			}

			let identitiesRequiringAuth = try await mapIdentity(preAuthToReview.addressesOfPersonasRequiringAuth)
			let accountsRequiringAuth = try mapAccount(preAuthToReview.addressesOfAccountsRequiringAuth)
			let entitiesRequiringAuth: OrderedSet<AccountOrPersona> = OrderedSet(accountsRequiringAuth.map { .account($0) } + identitiesRequiringAuth.map { .persona($0) })

			guard let signers = NonEmpty<Set<AccountOrPersona>>(entitiesRequiringAuth) else {
				return [:]
			}
			return try await factorSourcesClient.getSigningFactors(.init(networkID: networkId, signers: signers, signingPurpose: .signPreAuthorization))
		}

		let getPreview: GetPreview = { request in
			let preAuthToReview = try await analysePreview(request: request)
			let networkId = await gatewaysClient.getCurrentNetworkID()
			let signingFactors = try await getSigningFactors(networkId: networkId, preAuthToReview: preAuthToReview)

			return PreAuthorizationPreview(
				kind: preAuthToReview,
				networkId: networkId,
				signingFactors: signingFactors
			)
		}

		let buildSubintent: BuildSubintent = { request in
			let epoch = try await gatewayAPIClient.getEpoch()

			let header = IntentHeaderV2(
				networkId: request.networkId,
				startEpochInclusive: epoch,
				endEpochExclusive: epoch + Self.epochWindow,
				minProposerTimestampInclusive: nil, // TODO: Confirm
				maxProposerTimestampExclusive: nil, // TODO: Confirm
				intentDiscriminator: request.intentDiscriminator
			)

			return .init(
				header: header,
				manifest: request.manifest,
				message: .none
			)
		}

		return Self(
			getPreview: getPreview,
			buildSubintent: buildSubintent
		)
	}
}

private extension PreAuthToReview {
	var addressesOfPersonasRequiringAuth: [IdentityAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfPersonasRequiringAuth
		case let .enclosed(value):
			value.summary.addressesOfIdentitiesRequiringAuth
		}
	}

	var addressesOfAccountsRequiringAuth: [AccountAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfAccountsRequiringAuth
		case let .enclosed(value):
			value.summary.addressesOfAccountsRequiringAuth
		}
	}
}
