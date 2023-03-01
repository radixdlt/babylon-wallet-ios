import ClientPrelude
import GatewayAPI

extension ROLAClient {
	public static let liveValue = Self(
		performDappDefinitionVerification: { interaction async throws in
			@Dependency(\.gatewayAPIClient) var gatewayAPI

			let response = try await gatewayAPI.resourceDetailsByResourceIdentifier(interaction.metadata.dAppDefinitionAddress.address)

			let dict: [Metadata.Key: String] = .init(
				uniqueKeysWithValues: response.metadata.items.compactMap { item in
					guard let key = Metadata.Key(rawValue: item.key) else { return nil }
					return (key: key, value: item.value)
				}
			)

			let dAppDefinitionMetadata = DappDefinitionMetadata(
				accountType: dict[.accountType],
				relatedWebsites: dict[.relatedWebsites]
			)

			guard dAppDefinitionMetadata.accountType == Constants.dAppDefinitionAccountType else {
				throw ROLAFailure.wrongAccountType
			}

			guard dAppDefinitionMetadata.relatedWebsites == interaction.metadata.origin.rawValue else {
				throw ROLAFailure.unknownWebsite
			}
		},
		performWellKnownFileCheck: { interaction async throws in
			@Dependency(\.urlSession) var urlSession

			guard let originURL = URL(string: interaction.metadata.origin.rawValue) else {
				throw ROLAFailure.invalidOriginURL
			}
			let url = originURL.appending(path: Constants.wellKnownFilePath)

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

			let response: WellKnownFileResponse
			do {
				response = try JSONDecoder().decode(WellKnownFileResponse.self, from: data)
			} catch {
				throw ROLAFailure.radixJsonUnknownFileFormat
			}

			let dAppDefinitionAddresses = response.dApps.map(\.dAppDefinitionAddress)
			guard dAppDefinitionAddresses.contains(interaction.metadata.dAppDefinitionAddress) else {
				throw ROLAFailure.unknownDappDefinitionAddress
			}
		}
	)

	struct WellKnownFileResponse: Decodable {
		let dApps: [Item]

		struct Item: Decodable {
			let dAppDefinitionAddress: DappDefinitionAddress
		}
	}

	struct DappDefinitionMetadata {
		let accountType: String?
		let relatedWebsites: String?
	}

	enum Metadata {
		public enum Key: String, Sendable, Hashable {
			case accountType = "account_type"
			case relatedWebsites = "related_websites"
		}
	}

	enum Constants {
		static let wellKnownFilePath = ".well-known/radix.json"
		static let dAppDefinitionAccountType = "dapp definition"
	}
}
