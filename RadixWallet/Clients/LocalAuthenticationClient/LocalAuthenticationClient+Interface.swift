// MARK: - LocalAuthenticationClient
/// A client for querying if passcode and biometrics are set up.
struct LocalAuthenticationClient {
	var queryConfig: QueryConfig
	var authenticateWithBiometrics: AuthenticateWithBiometrics
	var setAuthenticatedSuccessfully: SetAuthenticatedSuccessfully
	var authenticatedSuccessfully: AuthenticatedSuccessfully
}

extension LocalAuthenticationClient {
	/// The return value (`LocalAuthenticationConfig`) might be `nil` if app goes to background or stuff like that.
	typealias QueryConfig = @Sendable () throws -> LocalAuthenticationConfig
	typealias AuthenticateWithBiometrics = @Sendable () async throws -> Bool
	typealias SetAuthenticatedSuccessfully = @Sendable () -> Void
	typealias AuthenticatedSuccessfully = @Sendable () -> AnyAsyncSequence<Void>
}
