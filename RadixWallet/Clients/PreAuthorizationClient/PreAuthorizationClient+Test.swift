extension DependencyValues {
	var preAuthorizationClient: PreAuthorizationClient {
		get { self[PreAuthorizationClient.self] }
		set { self[PreAuthorizationClient.self] = newValue }
	}
}

// MARK: - PreAuthorizationClient + TestDependencyKey
extension PreAuthorizationClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let noop = Self(
		getPreview: { _ in throw NoopError() },
		buildSubintent: { _ in throw NoopError() }
	)

	static let testValue = Self(
		getPreview: unimplemented("\(Self.self).getPreview"),
		buildSubintent: unimplemented("\(Self.self).buildSubintent")
	)
}
