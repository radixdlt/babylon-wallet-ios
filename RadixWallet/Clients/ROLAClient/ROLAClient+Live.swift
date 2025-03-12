import Sargon

extension ROLAClient {
	static let liveValue: Self = {
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		return Self(
			performDappDefinitionVerification: { metadata async throws in
				_ = try await onLedgerEntitiesClient.getDappMetadata(
					metadata.dappDefinitionAddress,
					validatingWebsite: metadata.origin.url()
				)
			},
			performWellKnownFileCheck: { url, dappDefinitionAddress async throws in
				@Dependency(\.urlSession) var urlSession

				let wellKnownURL = url.appending(path: Constants.wellKnownFilePath)

				let fetchWellKnownFile = {
					let (data, urlResponse) = try await urlSession.data(from: wellKnownURL)

					guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
						throw ExpectedHTTPURLResponse()
					}

					guard httpURLResponse.status == .ok else {
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
				guard dAppDefinitionAddresses.contains(dappDefinitionAddress) else {
					throw ROLAFailure.unknownDappDefinitionAddress
				}
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
		challenge: DappToWalletInteractionAuthChallengeNonce,
		dAppDefinitionAddress accountAddress: AccountAddress,
		origin metadataOrigin: DappOrigin
	) -> Data {
		let rPrefix: UInt8 = 0x52
		let dAppDefinitionAddress = accountAddress.address
		precondition(dAppDefinitionAddress.count <= UInt8.max)
		let challengeBytes = [UInt8](challenge.data.data)
		let lengthDappDefinitionAddress = UInt8(dAppDefinitionAddress.count)

		var data = [rPrefix]
		data.append(contentsOf: challengeBytes)
		data.append(contentsOf: [lengthDappDefinitionAddress])
		data.append(contentsOf: [UInt8](dAppDefinitionAddress.utf8))
		data.append(contentsOf: [UInt8](metadataOrigin.utf8))

		return Data(data)
	}
}

extension OnLedgerEntity.Metadata {
	func ownerKeyHashes() throws -> [Sargon.PublicKeyHash]? {
		try ownerKeys?.value.map { hash in
			switch hash {
			case let .ecdsaSecp256k1(value):
				let bytes = try Exactly29Bytes(hex: value)
				return .secp256k1(value: bytes)
			case let .eddsaEd25519(value):
				let bytes = try Exactly29Bytes(hex: value)
				return .ed25519(value: bytes)
			}
		}
	}
}
