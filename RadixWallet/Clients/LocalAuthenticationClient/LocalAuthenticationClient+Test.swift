
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
		authenticatedSuccessfully: unimplemented("\(Self.self).authenticatedSuccessfully")
	)
}
