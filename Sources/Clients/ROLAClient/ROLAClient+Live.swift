import ClientPrelude

extension ROLAClient {
	public static let liveValue = Self(
		performWellKnownFileCheck: { interaction async throws in
			@Dependency(\.urlSession) var urlSession

			guard let originURL = URL(string: interaction.metadata.origin.rawValue) else {
				throw WellKnownFileCheckError.invalidOriginURL
			}
			let wellKnownFilePath = ".well-known/radix.json"
			let url = originURL.appending(path: wellKnownFilePath)

			let (data, urlResponse) = try await urlSession.data(from: url)

			guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
				throw ExpectedHTTPURLResponse()
			}

			guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
				throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
			}

			let response: WellKnownFileResponse
			do {
				response = try JSONDecoder().decode(WellKnownFileResponse.self, from: data)
			} catch {
				throw WellKnownFileCheckError.invalidOriginURL
			}

			let dAppDefinitionAddresses = response.dApps.map(\.dAppDefinitionAddress)
			guard dAppDefinitionAddresses.contains(interaction.metadata.dAppDefinitionAddress.address) else {
				throw WellKnownFileCheckError.unknownDappDefinitionAddress
			}
		}
	)

	struct WellKnownFileResponse: Decodable {
		let dApps: [Item]

		struct Item: Decodable {
			let dAppDefinitionAddress: String
		}
	}
}

// MARK: - ROLAClient.WellKnownFileCheckError
extension ROLAClient {
	enum WellKnownFileCheckError: Error, LocalizedError {
		case invalidOriginURL
		case invalidWellKnownFileStructure
		case unknownDappDefinitionAddress
	}
}

// MARK: - ExpectedHTTPURLResponse
struct ExpectedHTTPURLResponse: Swift.Error {}

// MARK: - BadHTTPResponseCode
public struct BadHTTPResponseCode: Swift.Error {
	public let got: Int
	public let butExpected = Self.expected
	static let expected = 200
}
