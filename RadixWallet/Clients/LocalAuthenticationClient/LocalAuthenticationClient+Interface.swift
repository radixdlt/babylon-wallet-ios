// MARK: - LocalAuthenticationClient
/// A client for querying if passcode and biometrics are set up.
struct LocalAuthenticationClient: Sendable {
	var queryConfig: QueryConfig
	var authenticateWithBiometrics: AuthenticateWithBiometrics
	var setAuthenticatedSuccessfully: SetAuthenticatedSuccessfully
	var authenticatedSuccessfully: AuthenticatedSuccessfully

	init(
		queryConfig: @escaping QueryConfig,
		authenticateWithBiometrics: @escaping AuthenticateWithBiometrics,
		setAuthenticatedSuccessfully: @escaping SetAuthenticatedSuccessfully,
		authenticatedSuccessfully: @escaping AuthenticatedSuccessfully
	) {
		self.queryConfig = queryConfig
		self.authenticateWithBiometrics = authenticateWithBiometrics
		self.setAuthenticatedSuccessfully = setAuthenticatedSuccessfully
		self.authenticatedSuccessfully = authenticatedSuccessfully
	}
}

extension LocalAuthenticationClient {
	/// The return value (`LocalAuthenticationConfig`) might be `nil` if app goes to background or stuff like that.
	typealias QueryConfig = @Sendable () throws -> LocalAuthenticationConfig
	typealias AuthenticateWithBiometrics = @Sendable () async throws -> Bool
	typealias SetAuthenticatedSuccessfully = @Sendable () -> Void
	typealias AuthenticatedSuccessfully = @Sendable () -> AnyAsyncSequence<Void>
}
