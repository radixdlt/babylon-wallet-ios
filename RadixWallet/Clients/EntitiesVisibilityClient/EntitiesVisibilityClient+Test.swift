extension DependencyValues {
	public var entitiesVisibilityClient: EntitiesVisibilityClient {
		get { self[EntitiesVisibilityClient.self] }
		set { self[EntitiesVisibilityClient.self] = newValue }
	}
}

// MARK: - EntitiesVisibilityClient + TestDependencyKey
extension EntitiesVisibilityClient: TestDependencyKey {
	public static let noop = Self(
		hideAccounts: { _ in throw NoopError() },
		hidePersonas: { _ in throw NoopError() },
		unhideAllEntities: { throw NoopError() },
		getHiddenEntityCounts: { throw NoopError() }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		hideAccounts: unimplemented("\(Self.self).hideAccounts"),
		hidePersonas: unimplemented("\(Self.self).hidePersonas"),
		unhideAllEntities: unimplemented("\(Self.self).unhideAllEntities"),
		getHiddenEntityCounts: unimplemented("\(Self.self).getHiddenEntityCounts")
	)
}
