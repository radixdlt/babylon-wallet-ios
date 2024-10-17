// MARK: - DiskPersistenceClient + TestDependencyKey
extension DiskPersistenceClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		save: unimplemented("\(Self.self).save"),
		load: unimplemented("\(Self.self).load"),
		remove: unimplemented("\(Self.self).remove"),
		removeAll: unimplemented("\(Self.self).removeAll")
	)
}

extension DiskPersistenceClient {
	static let noop = Self(
		save: { _, _ in throw NoopError() },
		load: { _, _ in throw NoopError() },
		remove: { _ in throw NoopError() },
		removeAll: { throw NoopError() }
	)
}
