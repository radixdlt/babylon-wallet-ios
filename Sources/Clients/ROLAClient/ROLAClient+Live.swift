import CacheClient
import ClientPrelude
import Cryptography
import DeviceFactorSourceClient
import EngineToolkitClient
import GatewayAPI

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

		// FIXME: change to using hashes, which will happen... soon. Post Enkinet upgrade and once support in the
		// whole ecosystem.
		/// Tries to append a new Publickey to owner_keys
		// see Russ confluence page:
		/// https://radixdlt.atlassian.net/wiki/spaces/DevEcosystem/pages/3055026344/Metadata+Standards+for+Provable+Ownership+Encrypted+Messaging
		/// if it is already present, no change is done
		@Sendable func manifestAdding(
			ownerKey newPublicKey: SLIP10.PublicKey,
			for entity: EntityPotentiallyVirtual,
			assertingTransactionSigningKeyIsNotRemoved transactionSigningKey: SLIP10.PublicKey
		) async throws -> TransactionManifest {
			@Dependency(\.engineToolkitClient) var engineToolkitClient

			let entityAddress: String = {
				switch entity {
				case let .account(account):
					return account.address.address
				case let .persona(persona):
					return persona.address.address
				}
			}()
			let metadata = try await gatewayAPIClient.getEntityMetadata(entityAddress)
			var ownerKeys = try metadata.ownerKeys() ?? []
			loggerGlobal.debug("ownerKeys: \(ownerKeys)")
			ownerKeys.append(newPublicKey)
			if !ownerKeys.contains(transactionSigningKey) {
				loggerGlobal.debug("Did not contain transactionSigningKey, re-adding it: \(transactionSigningKey)")
				ownerKeys.append(transactionSigningKey)
			}

			loggerGlobal.notice("Setting ownerKeys to: \(ownerKeys)")

			let arrayOfEngineToolkitBytesValues: [ManifestASTValue] = ownerKeys.map { pubKey in
				ManifestASTValue.enum(
					.init(
						.publicKey,
						fields: [
							.enum(.init(
								pubKey.curveKindScryptoDiscriminatorByte,
								fields: [.bytes(pubKey.bytes)]
							)),
						]
					)
				)
			}

			// # Set List Metadata on Resource
			// https://github.com/radixdlt/radixdlt-scrypto/blob/main/transaction/examples/metadata/metadata.rtm#L97-L101
			let setMetadataInstruction = try SetMetadata(
				entityAddress: .init(address: entityAddress),
				key: SetMetadata.ownerKeysKey,
				value: Enum(
					.metadataEntry,
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

		// FIXME: Move this to `Signing` and change `Signing` to `UseFactors` which should be able to do both signing and derivation...?
		// Rationale: the solution below makes it impossible to create `authenticationSigning` key for Ledger factor sources :/
		@Sendable func manifestCreatingAuthKey(
			for entity: EntityPotentiallyVirtual
		) async throws -> ManifestForAuthKeyCreationResponse {
			@Dependency(\.factorSourcesClient) var factorSourcesClient

			let factorSourceID: FactorSourceID
			let authSignDerivationPath: DerivationPath
			let transactionSigning: FactorInstance
			let unsecuredEntityControl: UnsecuredEntityControl
			switch entity.securityState {
			case let .unsecured(unsecuredEntityControl_):
				unsecuredEntityControl = unsecuredEntityControl_
				transactionSigning = unsecuredEntityControl.transactionSigning
				guard unsecuredEntityControl.authenticationSigning == nil else {
					loggerGlobal.notice("Entity: \(entity) already has an authenticationSigning")
					throw EntityHasAuthSigningKeyAlready()
				}

				loggerGlobal.notice("Entity: \(entity) is about to create an authenticationSigning, publicKey of transactionSigning factor instance: \(unsecuredEntityControl.transactionSigning.publicKey)")
				factorSourceID = unsecuredEntityControl.transactionSigning.factorSourceID
				let hdPath = unsecuredEntityControl.transactionSigning.derivationPath
				switch entity {
				case .account:
					authSignDerivationPath = try hdPath.asAccountPath().switching(
						networkID: entity.networkID,
						keyKind: .authenticationSigning
					).wrapAsDerivationPath()
				case .persona:
					authSignDerivationPath = try hdPath.asIdentityPath().switching(
						keyKind: .authenticationSigning
					).wrapAsDerivationPath()
				}
			}
			let factorSources = try await factorSourcesClient.getFactorSources()
			guard
				let factorSource = factorSources[id: factorSourceID]
			else {
				fatalError()
			}

			let hdDeviceFactorSource = try HDOnDeviceFactorSource(factorSource: factorSource)

			let authenticationSigning: FactorInstance = try await {
				let publicKey = try await deviceFactorSourceClient.publicKeyFromOnDeviceHD(
					.init(
						hdOnDeviceFactorSource: hdDeviceFactorSource,
						derivationPath: authSignDerivationPath,
						curve: .curve25519, // we always use Curve25519 for new accounts
						loadMnemonicPurpose: .createSignAuthKey
					)
				)

				return try FactorInstance(
					factorSourceID: hdDeviceFactorSource.id,
					publicKey: .init(engine: publicKey),
					derivationPath: authSignDerivationPath
				)
			}()
			loggerGlobal.notice("Entity: \(entity) created and is about to upload authenticationSigning key: \(authenticationSigning.publicKey)")

			let manifest = try await manifestAdding(
				ownerKey: authenticationSigning.publicKey,
				for: entity,
				assertingTransactionSigningKeyIsNotRemoved: transactionSigning.publicKey
			)

			return ManifestForAuthKeyCreationResponse(manifest: manifest, authenticationSigning: authenticationSigning)
		}

		return Self(
			performDappDefinitionVerification: { metadata async throws in

				let metadataCollection = try await cacheClient.withCaching(
					cacheEntry: .rolaDappVerificationMetadata(metadata.dAppDefinitionAddress.address),
					request: {
						try await gatewayAPIClient.getEntityMetadata(metadata.dAppDefinitionAddress.address)
					}
				)

				let dict: [Metadata.Key: String] = .init(
					uniqueKeysWithValues: metadataCollection.items.compactMap { item in
						guard let key = Metadata.Key(rawValue: item.key),
						      let value = item.value.asString else { return nil }
						return (key: key, value: value)
					}
				)

				let dAppDefinitionMetadata = DappDefinitionMetadata(
					accountType: dict[.accountType],
					relatedWebsites: dict[.relatedWebsites]
				)

				guard dAppDefinitionMetadata.accountType == Constants.dAppDefinitionAccountType else {
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
			manifestForAuthKeyCreation: { request in
				try await manifestCreatingAuthKey(for: request.entity)
			},
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

	enum Metadata {
		enum Key: String, Sendable, Hashable {
			case accountType = "account_type"
			case relatedWebsites = "related_websites"
		}
	}

	enum Constants {
		static let wellKnownFilePath = ".well-known/radix.json"
		static let dAppDefinitionAccountType = "dapp definition"
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

extension GatewayAPI.EntityMetadataCollection {
	// FIXME: change to using hashes, which will happen... soon. Which will clean up this
	// terrible parsing mess.
	public func ownerKeys() throws -> OrderedSet<SLIP10.PublicKey>? {
		guard let response = items[customKey: SetMetadata.ownerKeysKey]?.asStringCollection else {
			return nil
		}

		// Element is String `"EddsaEd25519PublicKey("56d656000d5f67f5308951a394c7891c54b54dd633b42d1d21af372f80e6bc43")"`
		// or String `"EcdsaSecp256k1PublicKey("0256d656000d5f67f5308951a394c7891c54b54dd633b42d1d21af372f80e6bc43")"`
		let curve25519Prefix = "EddsaEd25519PublicKey"
		let secp256k1Prefix = "EcdsaSecp256k1PublicKey"
		let lengthCurve25519Prefix = curve25519Prefix.count
		let lengthSecp256k1Prefix = secp256k1Prefix.count
		let lengthQuoteAndParenthesis = 2
		let lengthQuotesAndTwoParenthesis = 2 * lengthQuoteAndParenthesis
		let lengthCurve25519PubKeyHex = 32 * 2
		let lengthSecp256K1PubKeyHex = 33 * 2
		let keys = try response.compactMap { elem -> Engine.PublicKey? in
			if elem.starts(with: curve25519Prefix) {
				guard elem.count == lengthQuotesAndTwoParenthesis + lengthCurve25519Prefix + lengthCurve25519PubKeyHex else {
					throw FailedToParsePublicKeyFromOwnerKeysBadLength()
				}
				var key = elem
				key.removeFirst(lengthCurve25519Prefix + lengthQuoteAndParenthesis)
				key.removeLast(lengthQuoteAndParenthesis)
				guard key.count == lengthCurve25519PubKeyHex else {
					return nil
				}
				return try .eddsaEd25519(.init(hex: key))

			} else if elem.starts(with: secp256k1Prefix) {
				guard elem.count == lengthQuotesAndTwoParenthesis + lengthSecp256k1Prefix + lengthSecp256K1PubKeyHex else {
					throw FailedToParsePublicKeyFromOwnerKeysBadLength()
				}
				var key = elem
				key.removeFirst(lengthSecp256k1Prefix + lengthQuoteAndParenthesis)
				key.removeLast(lengthQuoteAndParenthesis)
				guard key.count == lengthSecp256K1PubKeyHex else {
					return nil
				}
				return try .ecdsaSecp256k1(.init(hex: key))
			} else {
				return nil
			}
		}
		let slip10Keys = try keys.map { try SLIP10.PublicKey(engine: $0) }

		return try .init(
			validating: slip10Keys
		)
	}
}

// MARK: - FailedToParsePublicKeyFromOwnerKeysBadLength
struct FailedToParsePublicKeyFromOwnerKeysBadLength: Swift.Error {}

extension SLIP10.PublicKey {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	var curveKindScryptoDiscriminatorByte: EnumDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .u8(0x00)
		case .eddsaEd25519: return .u8(0x01)
		}
	}

	var bytes: EngineToolkitModels.Bytes {
		.init(bytes: Array(self.compressedRepresentation))
	}
}

extension EnumDiscriminator {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	public static let metadataEntry: Self = .u8(0x01)

	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	public static let publicKey: Self = .u8(0x09)
}
