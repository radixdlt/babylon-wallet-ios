// MARK: - LocalAuthenticationClient
/// A client for querying if passcode and biometrics are set up.
public struct LocalAuthenticationClient: Sendable {
	public var queryConfig: QueryConfig
	public var authenticateWithBiometrics: AuthenticateWithBiometrics
	public var setAuthenticatedSuccessfully: SetAuthenticatedSuccessfully
	public var authenticatedSuccessfully: AuthenticatedSuccessfully

	public init(
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
	public typealias QueryConfig = @Sendable () throws -> LocalAuthenticationConfig
	public typealias AuthenticateWithBiometrics = @Sendable () async throws -> Bool
	public typealias SetAuthenticatedSuccessfully = @Sendable () -> Void
	public typealias AuthenticatedSuccessfully = @Sendable () -> AnyAsyncSequence<Void>
}
