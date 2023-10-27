extension DependencyValues {
	public var entitiesVisibilityClient: EntitiesVisibilityClient {
		get { self[EntitiesVisibilityClient.self] }
		set { self[EntitiesVisibilityClient.self] = newValue }
	}
}

// MARK: - EntitiesVisibilityClient + TestDependencyKey
extension EntitiesVisibilityClient: TestDependencyKey {
	public static let noop = Self(
		hideAccount: { _ in throw NoopError() },
		hidePersona: { _ in throw NoopError() },
		unhideAllEntities: { throw NoopError() },
		getHiddenEntitiesStats: { throw NoopError() }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		hideAccount: unimplemented("\(Self.self).hideAccount"),
		hidePersona: unimplemented("\(Self.self).hidePersona"),
		unhideAllEntities: unimplemented("\(Self.self).unhideAllEntities"),
		getHiddenEntitiesStats: unimplemented("\(Self.self).getHiddenEntitiesStats")
	)
}
