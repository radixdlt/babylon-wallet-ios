// MARK: - HTTPClient
public struct HTTPClient: Sendable, DependencyKey {
	public let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	public typealias ExecuteRequest = @Sendable (_ request: URLRequest, _ isStatusCodeValid: ((Int) -> Bool)?) async throws -> Data
}
