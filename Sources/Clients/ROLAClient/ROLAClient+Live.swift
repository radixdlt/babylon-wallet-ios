import ClientPrelude

extension ROLAClient {
	public static let liveValue = Self(
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

	enum Constants {
		static let wellKnownFilePath = ".well-known/radix.json"
	}
}
