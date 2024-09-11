extension DependencyValues {
	public var resourcesVisibilityClient: ResourcesVisibilityClient {
		get { self[ResourcesVisibilityClient.self] }
		set { self[ResourcesVisibilityClient.self] = newValue }
	}
}

// MARK: - ResourcesVisibilityClient + TestDependencyKey
extension ResourcesVisibilityClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let noop = Self(
		hide: { _, _ in throw NoopError() },
		getHidden: { throw NoopError() },
		hiddenValues: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)

	public static let testValue = Self(
		hide: unimplemented("\(Self.self).hide"),
		getHidden: unimplemented("\(Self.self).getHidden"),
		hiddenValues: unimplemented("\(Self.self).hiddenValues")
	)
}
