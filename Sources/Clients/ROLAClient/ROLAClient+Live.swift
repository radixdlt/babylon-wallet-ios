import ClientPrelude

extension ROLAClient {
	public static let liveValue = Self(
		performWellKnownFileCheck: { interaction async throws in
			@Dependency(\.urlSession) var urlSession

			guard let originURL = URL(string: interaction.metadata.origin.rawValue) else {
				throw WellKnownCheckError.invalidURL
			}
			let wellKnownFilePath = ".well-known/radix.json"
			let url = originURL.appending(path: wellKnownFilePath)

			print("\(url)")
			let (data, response) = try await urlSession.data(from: url)
			print("🟢🟢🟢🟢🟢🟢")
			print(data)
			print(try JSONSerialization.jsonObject(with: data))
			print("=============================================")
			print(response)
			print("🟣🟣🟣🟣🟣🟣")
		}
	)
}

// MARK: - ROLAClient.WellKnownCheckError
extension ROLAClient {
	enum WellKnownCheckError: Error, LocalizedError {
		case invalidURL
	}
}
