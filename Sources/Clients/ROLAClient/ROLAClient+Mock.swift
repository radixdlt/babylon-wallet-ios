import ClientPrelude

// MARK: - ROLAClient + TestDependencyKey
extension ROLAClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		performDappDefinitionVerification: unimplemented("\(Self.self).performDappDefinitionVerification"),
		performWellKnownFileCheck: unimplemented("\(Self.self).performWellKnownFileCheck"),
		createAuthSigningKeyForAccountIfNeeded: unimplemented("\(Self.self).createAuthSigningKeyForAccountIfNeeded"),
		createAuthSigningKeyForPersonaIfNeeded: unimplemented("\(Self.self).createAuthSigningKeyForPersonaIfNeeded"),
		signAuthChallenge: unimplemented("\(Self.self).signAuthChallenge")
	)
}

extension ROLAClient {
	public static let noop = Self(
		performDappDefinitionVerification: { _ in },
		performWellKnownFileCheck: { _ in },
		createAuthSigningKeyForAccountIfNeeded: { _ in },
		createAuthSigningKeyForPersonaIfNeeded: { _ in },
		signAuthChallenge: { _ in throw NoopError() }
	)
}
