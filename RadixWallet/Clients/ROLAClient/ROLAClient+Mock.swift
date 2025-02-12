// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		authenticationDataToSignForChallenge: unimplemented("\(Self.self).authenticationDataToSignForChallenge")
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck")
	)
}

extension ROLAClient {
	static let noop = Self(
		performDappDefinitionVerification: { _ in },
		authenticationDataToSignForChallenge: { _ in throw NoopError() }
			performWellKnownFileCheck: { _, _ in }
	)
}
