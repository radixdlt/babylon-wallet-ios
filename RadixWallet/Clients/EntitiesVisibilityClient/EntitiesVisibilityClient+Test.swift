extension DependencyValues {
	var entitiesVisibilityClient: EntitiesVisibilityClient {
		get { self[EntitiesVisibilityClient.self] }
		set { self[EntitiesVisibilityClient.self] = newValue }
	}
}

// MARK: - EntitiesVisibilityClient + TestDependencyKey
extension EntitiesVisibilityClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let noop = Self(
		hideAccount: { _ in throw NoopError() },
		hidePersona: { _ in throw NoopError() },
		unhideAccount: { _ in throw NoopError() },
		unhidePersona: { _ in throw NoopError() },
		getHiddenEntities: { throw NoopError() }
	)

	static let testValue = Self(
		hideAccount: unimplemented("\(Self.self).hideAccount"),
		hidePersona: unimplemented("\(Self.self).hidePersona"),
		unhideAccount: unimplemented("\(Self.self).unhideAccount"),
		unhidePersona: unimplemented("\(Self.self).unhidePersona"),
		getHiddenEntities: unimplemented("\(Self.self).getHiddenEntities")
	)
}
