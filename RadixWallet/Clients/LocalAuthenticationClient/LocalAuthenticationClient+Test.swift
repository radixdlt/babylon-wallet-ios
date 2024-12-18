
extension DependencyValues {
	var localAuthenticationClient: LocalAuthenticationClient {
		get { self[LocalAuthenticationClient.self] }
		set { self[LocalAuthenticationClient.self] = newValue }
	}
}

// MARK: - LocalAuthenticationClient + TestDependencyKey
extension LocalAuthenticationClient: TestDependencyKey {
	static let testValue = Self(
		queryConfig: { .biometricsAndPasscodeSetUp },
		authenticateWithBiometrics: { true },
		setAuthenticatedSuccessfully: unimplemented("\(Self.self).setAuthenticatedSuccessfully"),
		authenticatedSuccessfully: noop.authenticatedSuccessfully
	)

	static let noop = Self(
		queryConfig: { throw NoopError() },
		authenticateWithBiometrics: { throw NoopError() },
		setAuthenticatedSuccessfully: {},
		authenticatedSuccessfully: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
