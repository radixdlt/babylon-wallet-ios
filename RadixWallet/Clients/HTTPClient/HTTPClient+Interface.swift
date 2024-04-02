// MARK: - HTTPClient
public struct HTTPClient: Sendable, DependencyKey {
	public let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	public typealias ExecuteRequest = @Sendable (URLRequest) async throws -> Data
}

extension HTTPClient {
	enum Constants {
		static let wellKnownFilePath = ".well-known/radix.json"
	}

	struct WellKnownFileResponse: Decodable {
		let dApps: [Item]
		let callbackPath: String?

		struct Item: Decodable {
			let dAppDefinitionAddress: DappDefinitionAddress
		}
	}

	enum DappWellKnownFileError: Error {
		case radixJsonNotFound
		case radixJsonUnknownFileFormat
	}

	func fetchDappWellKnownFile(_ originURL: URL) async throws -> WellKnownFileResponse {
		let url = originURL.appending(path: Constants.wellKnownFilePath)

		let data = try await executeRequest(.init(url: url))

		guard !data.isEmpty else {
			throw DappWellKnownFileError.radixJsonNotFound
		}

		do {
			return try JSONDecoder().decode(WellKnownFileResponse.self, from: data)
		} catch {
			throw DappWellKnownFileError.radixJsonUnknownFileFormat
		}
	}
}
