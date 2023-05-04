import AccountsClient
import CacheClient
import ClientPrelude
import Cryptography
import EngineToolkit
import GatewayAPI
import PersonasClient

extension ROLAClient {
	public static let liveValue: Self = {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.cacheClient) var cacheClient

		/// Tries to append the hash of a new Publickey to owner_keys
		// see Russ confluence page:
		/// https://radixdlt.atlassian.net/wiki/spaces/DevEcosystem/pages/3055026344/Metadata+Standards+for+Provable+Ownership+Encrypted+Messaging
		/// if it is already present, no change is done
		@Sendable func addOwnerKey<Entity: EntityProtocol>(
			hashing newPublicKeyToHash: SLIP10.PublicKey,
			for entity: Entity,
			buildSignAndSubmitTransactionManifest: (TransactionManifest, Entity) async throws -> Void
		) async throws {
			let entityAddress = entity.address.address
			let metadata = try await gatewayAPIClient.getEntityMetadata(entityAddress)
			var ownerKeyHashes = try metadata.ownerKeyHashes() ?? []
			let hashOfNewPublicKey = try blake2b(data: newPublicKeyToHash.compressedRepresentation)
			ownerKeyHashes.append(hashOfNewPublicKey)

			let arrayOfEngineToolkitBytesValues: [ManifestASTValue] = ownerKeyHashes.map {
				ManifestASTValue.bytes(Bytes(bytes: Array($0)))
			}

			// # Set List Metadata on Resource
			// https://github.com/radixdlt/radixdlt-scrypto/blob/main/transaction/examples/metadata/metadata.rtm#L97-L101
			let setMetadataInstruction = try SetMetadata(
				entityAddress: .init(address: entityAddress),
				key: GatewayAPI.EntityMetadataCollection.ownerKeysKey,
				value: Enum(
					.u8(1),
					fields: [.array(.init(
						elementKind: .bytes,
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
			try await buildSignAndSubmitTransactionManifest(manifest, entity)
			// TODO: caller of this function should update profile with new FactorInstance and update indices of
			// FactorSource if needed.
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
			createAuthSigningKeyForAccountIfNeeded: { _ in
				@Dependency(\.accountsClient) var accountsClient

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

	public func ownerKeyHashes() throws -> OrderedSet<Data>? {
		guard let ownerKeyHashesAsStringCollection = self[Self.ownerKeysKey]?.asStringCollection else {
			return nil
		}
		return try .init(
			validating: ownerKeyHashesAsStringCollection.map { try Data(hex: $0) }
		)
	}
}
