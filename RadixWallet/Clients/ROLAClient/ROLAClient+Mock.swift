// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck"),
		manifestForAuthKeyCreation: unimplemented("\(Self.self).manifestForAuthKeyCreation"),
		authenticationDataToSignForChallenge: unimplemented("\(Self.self).authenticationDataToSignForChallenge")
	)
}

extension ROLAClient {
	public static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _, _ in },
		manifestForAuthKeyCreation: { _ in throw NoopError() },
		authenticationDataToSignForChallenge: { _ in throw NoopError() }
	)
}
