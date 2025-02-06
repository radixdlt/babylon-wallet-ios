// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck"),
		manifestForAuthKeyCreation: unimplemented("\(Self.self).manifestForAuthKeyCreation")
	)
}

extension ROLAClient {
	static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _, _ in },
		manifestForAuthKeyCreation: { _ in throw NoopError() }
	)
}
