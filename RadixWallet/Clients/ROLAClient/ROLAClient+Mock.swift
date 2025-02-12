// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck"),
		authenticationDataToSignForChallenge: unimplemented("\(Self.self).authenticationDataToSignForChallenge")
	)
}

extension ROLAClient {
	static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _, _ in },
		authenticationDataToSignForChallenge: { _ in throw NoopError() }
	)
}
