extension DependencyValues {
	var entitiesInvolvedClient: EntitiesInvolvedClient {
		get { self[EntitiesInvolvedClient.self] }
		set { self[EntitiesInvolvedClient.self] = newValue }
	}
}

// MARK: - EntitiesInvolvedClient + TestDependencyKey
extension EntitiesInvolvedClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let noop = Self(
		getEntities: { _ in throw NoopError() }
	)

	static let testValue = Self(
		getEntities: unimplemented("\(Self.self).getEntities")
	)
}
