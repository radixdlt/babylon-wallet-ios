import ClientPrelude

// MARK: - CacheClient + TestDependencyKey
extension CacheClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		saveCodable: unimplemented("\(Self.self).saveCodable"),
		loadCodable: unimplemented("\(Self.self).loadCodable"),
		removeFile: unimplemented("\(Self.self).removeFile"),
		removeFolder: unimplemented("\(Self.self).removeFolder"),
		removeAll: unimplemented("\(Self.self).removeAll")
	)
}

extension CacheClient {
	public static let noop = Self(
		saveCodable: { _, _ in },
		loadCodable: { _, _ in throw NoopError() },
		removeFile: { _ in },
		removeFolder: { _ in },
		removeAll: {}
	)
}
