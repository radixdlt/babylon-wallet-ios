import ClientPrelude

// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck")
	)
}

extension ROLAClient {
	public static let noop = Self(
		performWellKnownFileCheck: { _ in }
	)
}
