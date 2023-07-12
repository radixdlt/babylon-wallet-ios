import CacheClient
import ClientPrelude
import Cryptography
import DeviceFactorSourceClient
import GatewayAPI
import RegexBuilder

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		let manifestForAuthKeyCreation: ManifestForAuthKeyCreation = { request in
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
					return try .init(hashing: control.transactionSigning.publicKey)
				}
			}()

			loggerGlobal.debug("ownerKeyHashes: \(ownerKeyHashes)")
			try ownerKeyHashes.append(.init(hashing: newPublicKey))

			if !ownerKeyHashes.contains(transactionSigningKeyHash) {
				loggerGlobal.debug("Did not contain transactionSigningKey hash, re-adding it: \(transactionSigningKeyHash)")
				ownerKeyHashes.append(transactionSigningKeyHash)
			}

			loggerGlobal.notice("Setting ownerKeyHashes to: \(ownerKeyHashes)")
			return try .manifestForOwnerKeys(address: entityAddress.address, keyHashes: ownerKeyHashes, networkID: entity.networkID)
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

	public init(hashing publicKey: SLIP10.PublicKey) throws {
		let hashBytes = try blake2b(data: publicKey.compressedData).suffix(Self.hashLength)

		guard
			hashBytes.count == Self.hashLength
		else {
			throw InvalidPublicKeyHashLength(got: hashBytes.count, expected: Self.hashLength)
		}

		switch publicKey {
		case .ecdsaSecp256k1:
			self = .ecdsaSecp256k1(value: hashBytes.bytes)
		case .eddsaEd25519:
			self = .eddsaEd25519(value: hashBytes.bytes)
		}
	}
}

extension GatewayAPI.EntityMetadataCollection {
	// FIXME: change to using hashes, which will happen... soon. Which will clean up this
	// terrible parsing mess.
	public func ownerKeyHashes() throws -> [PublicKeyHash]? {
		guard let response = items[customKey: "owner_keys"]?.asStringCollection else {
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

			let bytes = try [UInt8].init(hex: String(hash))
			if hashType == curve25519Prefix {
				return .eddsaEd25519(value: bytes)
			} else if hashType == secp256k1Prefix {
				return .ecdsaSecp256k1(value: bytes)
			} else {
				return nil
			}
		}
	}
}
