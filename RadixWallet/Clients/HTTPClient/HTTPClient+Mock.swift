// MARK: - HTTPClient + TestDependencyKey
extension HTTPClient: TestDependencyKey {
	public static let previewValue = Self.noop()

	public static let testValue = Self(
		executeRequest: unimplemented("\(Self.self).executeRequest")
	)

	private static func noop() -> Self {
		.init(
			executeRequest: { _ in Data() }
		)
	}
}

extension DependencyValues {
	public var httpClient: HTTPClient {
		get { self[HTTPClient.self] }
		set { self[HTTPClient.self] = newValue }
	}
}
