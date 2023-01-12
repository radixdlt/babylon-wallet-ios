import ClientPrelude

public extension DependencyValues {
	var fileClient: FileClient {
		get { self[FileClient.self] }
		set { self[FileClient.self] = newValue }
	}
}

// MARK: - FileClient + TestDependencyKey
extension FileClient: TestDependencyKey {
	public static let previewValue = Self(
		read: { _, _ in Data() }
	)

	public static let testValue = Self(
		read: unimplemented("\(Self.self).read")
	)
}
