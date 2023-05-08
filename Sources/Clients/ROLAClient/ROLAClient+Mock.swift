import ClientPrelude

// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck"),
		manifestForAuthKeyCreation: unimplemented("\(Self.self).manifestForAuthKeyCreation"),
		signAuthChallenge: unimplemented("\(Self.self).signAuthChallenge")
	)
}

extension ROLAClient {
	public static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _ in },
		manifestForAuthKeyCreation: { _ in throw NoopError() },
		signAuthChallenge: { _ in throw NoopError() }
	)
}
