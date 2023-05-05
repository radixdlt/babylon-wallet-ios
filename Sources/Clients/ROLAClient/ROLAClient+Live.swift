import AccountsClient
import CacheClient
import ClientPrelude
import Cryptography
import DeviceFactorSourceClient
import EngineToolkit
import FaucetClient // Actually just `SignSubmitSimpleTX`
import GatewayAPI
import PersonasClient

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient

		/// Tries to append a new Publickey to owner_keys
		// see Russ confluence page:
		/// https://radixdlt.atlassian.net/wiki/spaces/DevEcosystem/pages/3055026344/Metadata+Standards+for+Provable+Ownership+Encrypted+Messaging
		/// if it is already present, no change is done
		@Sendable func addOwnerKey<Entity: EntityProtocol>(
			hashing newPublicKeyToHas: SLIP10.PublicKey,
			for entity: Entity
		) async throws {
			@Dependency(\.faucetClient) var faucetClient

			let entityAddress = entity.address.address
			let metadata = try await gatewayAPIClient.getEntityMetadata(entityAddress)
			var ownerKeys = try metadata.ownerKeys() ?? []
//			let hashOfPublicKey = try blake2b(data: newPublicKeyToHash.compressedRepresentation)
//			let hashBytesOfPublicKey = Data(hashOfPublicKey.suffix(29))
//			ownerKeyHashes.append(hashBytesOfPublicKey)

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
				key: GatewayAPI.EntityMetadataCollection.ownerKeysKey,
				value: Enum(
					.metadataEntry,
					fields: [.array(.init(
						elementKind: .enum,
						elements: arrayOfEngineToolkitBytesValues
					)
					)]
				)
			)

			let manifest = TransactionManifest(
				instructions: [
					.setMetadata(setMetadataInstruction),
				]
			)

			try await faucetClient.signSubmitSimpleTX(manifest)
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

				guard dAppDefinitionMetadata.relatedWebsites == metadata.origin.rawValue else {
					throw ROLAFailure.unknownWebsite
				}
			},
			performWellKnownFileCheck: { metadata async throws in
				@Dependency(\.urlSession) var urlSession

				guard let originURL = URL(string: metadata.origin.rawValue) else {
					throw ROLAFailure.invalidOriginURL
				}
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
			createAuthSigningKeyForAccountIfNeeded: { request in
				var account = request.account
				@Dependency(\.accountsClient) var accountsClient
				@Dependency(\.factorSourcesClient) var factorSourcesClient
				@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

				let factorSourceID: FactorSourceID
				let signingKeyDerivationPath: AccountBabylonDerivationPath
				var unsecuredEntityControl: UnsecuredEntityControl
				switch account.securityState {
				case let .unsecured(unsecuredEntityControl_):
					unsecuredEntityControl = unsecuredEntityControl_
					guard unsecuredEntityControl.authenticationSigning == nil else {
						return
					}

					factorSourceID = unsecuredEntityControl.transactionSigning.factorSourceID
					guard let hdPath = unsecuredEntityControl.transactionSigning.derivationPath else {
						fatalError()
					}
					signingKeyDerivationPath = try hdPath.asAccountPath().asBabylonAccountPath()
				}
				let factorSources = try await factorSourcesClient.getFactorSources()
				guard
					let factorSource = factorSources[id: factorSourceID]
				else {
					fatalError()
				}

				let babylonDeviceFactorSource = try BabylonDeviceFactorSource(factorSource: factorSource)
				let authKeyDerivationPath = try signingKeyDerivationPath.switching(keyKind: .authenticationSigning)
				let derivationPath = authKeyDerivationPath.wrapAsDerivationPath()

				let authenticationSigning: FactorInstance = try await {
					let publicKey = try await deviceFactorSourceClient.publicKeyFromOnDeviceHD(
						.init(
							hdOnDeviceFactorSource: babylonDeviceFactorSource.hdOnDeviceFactorSource,
							derivationPath: derivationPath,
							curve: .curve25519, // we always use Curve25519 for new accounts
							loadMnemonicPurpose: .createSignAuthKey
						)
					)

					return try FactorInstance(
						factorSourceID: babylonDeviceFactorSource.id,
						publicKey: .init(engine: publicKey),
						derivationPath: derivationPath
					)
				}()

				try await addOwnerKey(hashing: authenticationSigning.publicKey, for: account)
				unsecuredEntityControl.authenticationSigning = authenticationSigning
				account.securityState = .unsecured(unsecuredEntityControl)

				try await accountsClient.updateAccount(account)
				// DONE

			},
			createAuthSigningKeyForPersonaIfNeeded: { _ in }
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

extension GatewayAPI.EntityMetadataCollection {
	public static let ownerKeysKey = "owner_keys"

	public func ownerKeys() throws -> OrderedSet<SLIP10.PublicKey>? {
		guard let ownerKeysAsStringCollection = self[Self.ownerKeysKey]?.asStringCollection else {
			return nil
		}
		return try .init(
			validating: ownerKeysAsStringCollection.map { try Data(hex: $0) }.map { try SLIP10.PublicKey(data: $0) }
		)
	}
}

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
