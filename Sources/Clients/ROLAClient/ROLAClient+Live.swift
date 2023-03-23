import CacheClient
import ClientPrelude
import GatewayAPI

extension ROLAClient {
	public static let liveValue = Self(
		performDappDefinitionVerification: { metadata async throws in
			@Dependency(\.gatewayAPIClient) var gatewayAPIClient
			@Dependency(\.cacheClient) var cacheClient

			let metadataCollection: GatewayAPI.EntityMetadataCollection
			let cacheEntry: CacheClient.Entry = .rolaDappVerificationMetadata(metadata.dAppDefinitionAddress.address)
			if let data = try? cacheClient.load(GatewayAPI.EntityMetadataCollection.self, cacheEntry) as? GatewayAPI.EntityMetadataCollection {
				metadataCollection = data
			} else {
				metadataCollection = try await gatewayAPIClient.getEntityMetadata(metadata.dAppDefinitionAddress.address)
				cacheClient.save(metadataCollection, cacheEntry)
			}

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
			@Dependency(\.cacheClient) var cacheClient

			guard let originURL = URL(string: metadata.origin.rawValue) else {
				throw ROLAFailure.invalidOriginURL
			}
			let url = originURL.appending(path: Constants.wellKnownFilePath)

			let response: WellKnownFileResponse
			let cacheEntry: CacheClient.Entry = .rolaWellKnownFileVerification(url.absoluteString)
			if let data = try? cacheClient.load(WellKnownFileResponse.self, cacheEntry) as? WellKnownFileResponse {
				response = data
			} else {
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
					response = try JSONDecoder().decode(WellKnownFileResponse.self, from: data)
					cacheClient.save(response, cacheEntry)
				} catch {
					throw ROLAFailure.radixJsonUnknownFileFormat
				}
			}

			let dAppDefinitionAddresses = response.dApps.map(\.dAppDefinitionAddress)
			guard dAppDefinitionAddresses.contains(metadata.dAppDefinitionAddress) else {
				throw ROLAFailure.unknownDappDefinitionAddress
			}
		}
	)

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
