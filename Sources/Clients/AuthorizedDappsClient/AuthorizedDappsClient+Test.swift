import ClientPrelude

extension DependencyValues {
	public var authorizedDappsClient: AuthorizedDappsClient {
		get { self[AuthorizedDappsClient.self] }
		set { self[AuthorizedDappsClient.self] = newValue }
	}
}

// MARK: - AuthorizedDappsClient + TestDependencyKey
extension AuthorizedDappsClient: TestDependencyKey {
	public static let previewValue = Self()
	public static let testValue = Self()
}
