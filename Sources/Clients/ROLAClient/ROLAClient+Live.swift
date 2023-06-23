import CacheClient
import ClientPrelude
import Cryptography
import DeviceFactorSourceClient
import EngineToolkitClient
import GatewayAPI
import RegexBuilder

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		let manifestForAuthKeyCreation: ManifestForAuthKeyCreation = { request in
			@Dependency(\.engineToolkitClient) var engineToolkitClient
			let entity = request.entity
			let newPublicKey = request.newPublicKey

			let entityAddress: Address = {
				switch entity {
				case let .account(account):
					return account.address.asGeneral()
				case let .persona(persona):
					return persona.address.asGeneral()
				}
			}()
			let metadata = try await gatewayAPIClient.getEntityMetadata(entityAddress.address)
			var ownerKeyHashes = try metadata.ownerKeyHashes() ?? []

			let transactionSigningKeyHash: PublicKeyHash = try {
				switch entity.securityState {
				case let .unsecured(control):
					return try .init(from: control.transactionSigning.publicKey)
				}
			}()

			loggerGlobal.debug("ownerKeyHashes: \(ownerKeyHashes)")
			try ownerKeyHashes.append(.init(from: newPublicKey))

			if !ownerKeyHashes.contains(transactionSigningKeyHash) {
				loggerGlobal.debug("Did not contain transactionSigningKey hash, re-adding it: \(transactionSigningKeyHash)")
				ownerKeyHashes.append(transactionSigningKeyHash)
			}

			loggerGlobal.notice("Setting ownerKeyHashes to: \(ownerKeyHashes)")

			let arrayOfEngineToolkitBytesValues: [ManifestASTValue] = try ownerKeyHashes.map { hash in
				try ManifestASTValue.enum(
					.init(hash.curveKindScryptoDiscriminator, fields: [.bytes(hash.bytes())])
				)
			}

			// # Set List Metadata on Resource
			// https://github.com/radixdlt/radixdlt-scrypto/blob/main/transaction/examples/metadata/metadata.rtm#L97-L101
			let setMetadataInstruction = try SetMetadata(
				entityAddress: entityAddress,
				key: SetMetadata.ownerKeysKey,
				value: Enum(
					.metadata_PublicKeyHashArray,
					fields: [.array(.init(
						elementKind: .enum,
						elements: arrayOfEngineToolkitBytesValues
					)
					)]
				)
			)

			let manifestParsed = TransactionManifest(
				instructions: [
					.setMetadata(setMetadataInstruction),
				]
			)

			let manifestString = try engineToolkitClient.convertManifestToString(.init(
				version: .default,
				networkID: entity.networkID,
				manifest: manifestParsed
			))

			return manifestString
		}

		return Self(
			performDappDefinitionVerification: { metadata async throws in

				let metadataCollection = try await cacheClient.withCaching(
					cacheEntry: .rolaDappVerificationMetadata(metadata.dAppDefinitionAddress.address),
					request: {
						try await gatewayAPIClient.getEntityMetadata(metadata.dAppDefinitionAddress.address)
					}
				)

				let dict: [EntityMetadataKey: String] = .init(
					uniqueKeysWithValues: metadataCollection.items.compactMap { item in
						guard let key = EntityMetadataKey(rawValue: item.key),
						      let value = item.value.asString else { return nil }
						return (key: key, value: value)
					}
				)

				let dAppDefinitionMetadata = DappDefinitionMetadata(
					accountType: dict[.accountType],
					relatedWebsites: dict[.relatedWebsites]
				)

				guard dAppDefinitionMetadata.accountType == GatewayAPI.EntityMetadataCollection.AccountType.dappDefinition.rawValue else {
					throw ROLAFailure.wrongAccountType
				}

				guard dAppDefinitionMetadata.relatedWebsites == metadata.origin.urlString.rawValue else {
					throw ROLAFailure.unknownWebsite
				}
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

/// `challenge(32) || L_dda(1) || dda_utf8(L_dda) || origin_utf8`
func payloadToHash(
	challenge: P2P.Dapp.Request.AuthChallengeNonce,
	dAppDefinitionAddress accountAddress: AccountAddress,
	origin metadataOrigin: P2P.Dapp.Request.Metadata.Origin
) -> Data {
	let dAppDefinitionAddress = accountAddress.address
	let origin = metadataOrigin.urlString.rawValue
	precondition(dAppDefinitionAddress.count <= UInt8.max)
	let challengeBytes = [UInt8](challenge.data.data)
	let lengthDappDefinitionAddress = UInt8(dAppDefinitionAddress.count)
	return Data(challengeBytes + [lengthDappDefinitionAddress] + [UInt8](dAppDefinitionAddress.utf8) + [UInt8](origin.utf8))
}

extension PublicKeyHash {
	public struct InvalidPublicKeyHashLength: Error {
		public let got: Int
		public let expected: Int
	}

	static let hashLength = 29

	public init(from publicKey: SLIP10.PublicKey) throws {
		let hashBytes = try blake2b(data: publicKey.compressedData).suffix(Self.hashLength)

		guard hashBytes.count == Self.hashLength else {
			throw InvalidPublicKeyHashLength(got: hashBytes.count, expected: Self.hashLength)
		}

		let hex = String(hashBytes.hex)

		switch publicKey {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(hex)
		case .eddsaEd25519:
			self = .eddsaEd25519(hex)
		}
	}
}

extension GatewayAPI.EntityMetadataCollection {
	// FIXME: change to using hashes, which will happen... soon. Which will clean up this
	// terrible parsing mess.
	public func ownerKeyHashes() throws -> [PublicKeyHash]? {
		guard let response = items[customKey: SetMetadata.ownerKeysKey]?.asStringCollection else {
			return nil
		}

		let curve25519Prefix = "EddsaEd25519PublicKeyHash"
		let secp256k1Prefix = "EcdsaSecp256k1PublicKeyHash"

		let regex = Regex {
			Capture {
				ChoiceOf {
					curve25519Prefix
					secp256k1Prefix
				}
			}
			"(\""
			Capture {
				OneOrMore {
					CharacterClass.hexDigit
				}
			}
			"\")"
		}

		return try response.compactMap { elem -> PublicKeyHash? in
			guard let output = try regex.wholeMatch(in: elem)?.output else {
				return nil
			}

			let (_, hashType, hash) = output

			if hashType == curve25519Prefix {
				return .eddsaEd25519(String(hash))
			} else if hashType == secp256k1Prefix {
				return .ecdsaSecp256k1(String(hash))
			} else {
				return nil
			}
		}
	}
}

extension PublicKeyHash {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	var curveKindScryptoDiscriminator: EnumDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .string(.publicKeyHash_Secp256k1)
		case .eddsaEd25519: return .string(.publicKeyHash_Ed25519)
		}
	}

	func bytes() throws -> Bytes {
		try Bytes(hex: hash)
	}
}
