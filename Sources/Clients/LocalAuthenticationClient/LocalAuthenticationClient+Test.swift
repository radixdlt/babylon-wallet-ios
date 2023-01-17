import ClientPrelude

public extension DependencyValues {
	var localAuthenticationClient: LocalAuthenticationClient {
		get { self[LocalAuthenticationClient.self] }
		set { self[LocalAuthenticationClient.self] = newValue }
	}
}

// MARK: - LocalAuthenticationClient + TestDependencyKey
extension LocalAuthenticationClient: TestDependencyKey {
	public static let testValue = Self(
		queryConfig: { .biometricsAndPasscodeSetUp }
	)
}
