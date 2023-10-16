import EngineToolkit

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		let manifestForAuthKeyCreation: ManifestForAuthKeyCreation = { request in
			let entity = request.entity
			let newPublicKey = request.newPublicKey

			let entityAddress: Address = switch entity {
			case let .account(account):
				account.address.asGeneral
			case let .persona(persona):
				persona.address.asGeneral
			}
			let metadata = try await onLedgerEntitiesClient.getEntity(entityAddress, metadataKeys: [.ownerKeys]).genericComponent?.metadata
			var ownerKeyHashes = try metadata?.ownerKeyHashes() ?? []

			let transactionSigningKeyHash: PublicKeyHash = switch entity.securityState {
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
				_ = try await cacheClient.withCaching(
					cacheEntry: .rolaDappVerificationMetadata(metadata.dAppDefinitionAddress.address),
					request: {
						try await onLedgerEntitiesClient.getDappMetadata(
							metadata.dAppDefinitionAddress,
							validatingWebsite: metadata.origin.url
						)
					}
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

				let response = try await cacheClient.withCaching(
					cacheEntry: .rolaWellKnownFileVerification(url.absoluteString),
					request: fetchWellKnownFile
				)

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

/// `0x52 || challenge(32) || L_dda(1) || dda_utf8(L_dda) || origin_utf8`
func payloadToHash(
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
	return Data(
		[rPrefix]
			+ challengeBytes
			+ [lengthDappDefinitionAddress]
			+ [UInt8](dAppDefinitionAddress.utf8)
			+ [UInt8](origin.utf8)
	)
}

extension EngineToolkit.PublicKeyHash {
	public struct InvalidPublicKeyHashLength: Error {
		public let got: Int
		public let expected: Int
	}

	static let hashLength = 29

	public init(hashing publicKey: SLIP10.PublicKey) throws {
		let hashBytes = try blake2b(data: publicKey.compressedData).suffix(Self.hashLength)

		guard
			hashBytes.count == Self.hashLength
		else {
			throw InvalidPublicKeyHashLength(got: hashBytes.count, expected: Self.hashLength)
		}

		switch publicKey {
		case .ecdsaSecp256k1:
			self = .secp256k1(value: hashBytes.bytes)
		case .eddsaEd25519:
			self = .ed25519(value: hashBytes.bytes)
		}
	}
}

extension OnLedgerEntity.Metadata {
	public func ownerKeyHashes() throws -> [EngineToolkit.PublicKeyHash]? {
		try ownerKeys?.compactMap { hash in
			switch hash {
			case let .ecdsaSecp256k1(value):
				let bytes = try [UInt8].init(hex: value)
				return .secp256k1(value: bytes)
			case let .eddsaEd25519(value):
				let bytes = try [UInt8].init(hex: value)
				return .ed25519(value: bytes)
			}
		}
	}
}
