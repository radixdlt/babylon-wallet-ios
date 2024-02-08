

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		let manifestForAuthKeyCreation: ManifestForAuthKeyCreation = { request in
			let entity = request.entity
			let newPublicKey = request.newPublicKey

			var entityAddress: Address! = nil
			let metadata = try await onLedgerEntitiesClient.getEntity(entityAddress, metadataKeys: [.ownerKeys]).genericComponent?.metadata
			var ownerKeyHashes = try metadata?.ownerKeyHashes() ?? []

			let transactionSigningKeyHash: EnginePublicKeyHash = switch entity.securityState {
			case let .unsecured(control):
				try .init(hashing: control.transactionSigning.publicKey)
			}

			loggerGlobal.debug("ownerKeyHashes: \(ownerKeyHashes)")
			try ownerKeyHashes.append(.init(hashing: newPublicKey))

			if !ownerKeyHashes.contains(transactionSigningKeyHash) {
				loggerGlobal.debug("Did not contain transactionSigningKey hash, re-adding it: \(transactionSigningKeyHash)")
				ownerKeyHashes.append(transactionSigningKeyHash)
			}

			loggerGlobal.notice("Setting ownerKeyHashes to: \(ownerKeyHashes)")
			return try ManifestBuilder()
				.setOwnerKeys(
					from: entityAddress,
					ownerKeyHashes: ownerKeyHashes
				)
				.build(networkId: request.entity.networkID.rawValue)
		}

		return Self(
			performDappDefinitionVerification: { metadata async throws in
				_ = try await onLedgerEntitiesClient.getDappMetadata(
					metadata.dAppDefinitionAddress,
					validatingWebsite: metadata.origin.url
				)
			},
			performWellKnownFileCheck: { metadata async throws in
				@Dependency(\.urlSession) var urlSession

				let originURL = metadata.origin.url

				let url = originURL.appending(path: Constants.wellKnownFilePath)

				let fetchWellKnownFile = {
					let (data, urlResponse) = try await urlSession.data(from: url)

					guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
						throw ExpectedHTTPURLResponse()
					}

					guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
						throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
					}

					guard !data.isEmpty else {
						throw ROLAFailure.radixJsonNotFound
					}

					do {
						let response = try JSONDecoder().decode(WellKnownFileResponse.self, from: data)
						return response
					} catch {
						throw ROLAFailure.radixJsonUnknownFileFormat
					}
				}

				let response = try await fetchWellKnownFile()

				let dAppDefinitionAddresses = response.dApps.map(\.dAppDefinitionAddress)
				guard dAppDefinitionAddresses.contains(metadata.dAppDefinitionAddress) else {
					throw ROLAFailure.unknownDappDefinitionAddress
				}
			},
			manifestForAuthKeyCreation: manifestForAuthKeyCreation,
			authenticationDataToSignForChallenge: { request in

				let payload = payloadToHash(
					challenge: request.challenge,
					dAppDefinitionAddress: request.dAppDefinitionAddress,
					origin: request.origin
				)

				return AuthenticationDataToSignForChallengeResponse(
					input: request,
					payloadToHashAndSign: payload
				)
			}
		)
	}()

	struct WellKnownFileResponse: Codable {
		let dApps: [Item]

		struct Item: Codable {
			let dAppDefinitionAddress: DappDefinitionAddress
		}
	}

	struct DappDefinitionMetadata {
		let accountType: String?
		let relatedWebsites: String?
	}

	enum Constants {
		static let wellKnownFilePath = ".well-known/radix.json"
	}
}

extension ROLAClient {
	/// `0x52 || challenge(32) || L_dda(1) || dda_utf8(L_dda) || origin_utf8`
	static func payloadToHash(
		challenge: P2P.Dapp.Request.AuthChallengeNonce,
		dAppDefinitionAddress accountAddress: AccountAddress,
		origin metadataOrigin: P2P.Dapp.Request.Metadata.Origin
	) -> Data {
		let rPrefix: UInt8 = 0x52
		let dAppDefinitionAddress = accountAddress.address
		let origin = metadataOrigin.urlString.rawValue
		precondition(dAppDefinitionAddress.count <= UInt8.max)
		let challengeBytes = [UInt8](challenge.data.data)
		let lengthDappDefinitionAddress = UInt8(dAppDefinitionAddress.count)

		var data = [rPrefix]
		data.append(contentsOf: challengeBytes)
		data.append(contentsOf: [lengthDappDefinitionAddress])
		data.append(contentsOf: [UInt8](dAppDefinitionAddress.utf8))
		data.append(contentsOf: [UInt8](origin.utf8))

		return Data(data)
	}
}

extension OnLedgerEntity.Metadata {
	public func ownerKeyHashes() throws -> [EnginePublicKeyHash]? {
		try ownerKeys?.value.map { hash in
			switch hash {
			case let .ecdsaSecp256k1(value):
				let bytes = try Data(hex: value)
				return .secp256k1(value: bytes)
			case let .eddsaEd25519(value):
				let bytes = try Data(hex: value)
				return .ed25519(value: bytes)
			}
		}
	}
}
