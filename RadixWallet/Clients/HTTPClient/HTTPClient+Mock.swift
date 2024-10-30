// MARK: - HTTPClient + TestDependencyKey
extension HTTPClient: TestDependencyKey {
	static let previewValue = Self.noop()

	static let testValue = Self(
		executeRequest: unimplemented("\(Self.self).executeRequest")
	)

	private static func noop() -> Self {
		.init(
			executeRequest: { _, _ in Data() }
		)
	}
}

extension DependencyValues {
	var httpClient: HTTPClient {
		get { self[HTTPClient.self] }
		set { self[HTTPClient.self] = newValue }
	}
}
