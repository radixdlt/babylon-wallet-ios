// MARK: - HTTPClient
public struct HTTPClient: Sendable, DependencyKey {
	public let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	public typealias ExecuteRequest = @Sendable (URLRequest) async throws -> Data
}
