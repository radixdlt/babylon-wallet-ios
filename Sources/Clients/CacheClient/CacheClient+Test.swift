import ClientPrelude

// MARK: - CacheClient + TestDependencyKey
extension CacheClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		save: unimplemented("\(Self.self).save"),
		load: unimplemented("\(Self.self).load"),
		removeFile: unimplemented("\(Self.self).removeFile"),
		removeFolder: unimplemented("\(Self.self).removeFolder"),
		removeAll: unimplemented("\(Self.self).removeAll")
	)
}

extension CacheClient {
	public static let noop = Self(
		save: { _, _ in },
		load: { _, _ in throw NoopError() },
		removeFile: { _ in },
		removeFolder: { _ in },
		removeAll: {}
	)
}
