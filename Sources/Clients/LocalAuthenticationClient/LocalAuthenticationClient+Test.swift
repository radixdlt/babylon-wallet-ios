import Dependencies

public extension DependencyValues {
	var localAuthenticationClient: LocalAuthenticationClient {
		get { self[LocalAuthenticationClient.self] }
		set { self[LocalAuthenticationClient.self] = newValue }
	}
}
