
// MARK: - LocalAuthenticationClient

/// A client for querying if passcode and biometrics are set up.
public struct LocalAuthenticationClient: Sendable {
	/// The return value (`LocalAuthenticationConfig`) might be `nil` if app goes to background or stuff like that.
	public typealias QueryConfig = @Sendable () throws -> LocalAuthenticationConfig

	public var queryConfig: QueryConfig

	public init(queryConfig: @escaping QueryConfig) {
		self.queryConfig = queryConfig
	}
}
