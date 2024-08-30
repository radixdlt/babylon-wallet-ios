// MARK: - HTTPClient
public struct HTTPClient: Sendable, DependencyKey {
	public let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	public typealias ExecuteRequest = @Sendable (_ request: URLRequest, _ acceptedStatusCodes: [HTTPStatusCode]) async throws -> Data
}

extension HTTPClient {
	func executeRequest(_ request: URLRequest) async throws -> Data {
		try await executeRequest(request, [.ok])
	}
}
