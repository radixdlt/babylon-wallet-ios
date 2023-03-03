import ClientPrelude

extension DependencyValues {
	public var factorSourcesClient: FactorSourcesClient {
		get { self[FactorSourcesClient.self] }
		set { self[FactorSourcesClient.self] = newValue }
	}
}

// MARK: - FactorSourcesClient + TestDependencyKey
extension FactorSourcesClient: TestDependencyKey {
	public static let previewValue: Self = noop
	public static let testValue = Self(
		getFactorSources: unimplemented("\(Self.self).getFactorSources")
	)

	public static let noop = Self(
		getFactorSources: { throw NoopError() }
	)
}
