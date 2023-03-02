import ClientPrelude

// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck")
	)
}

extension ROLAClient {
	public static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _ in }
	)
}
