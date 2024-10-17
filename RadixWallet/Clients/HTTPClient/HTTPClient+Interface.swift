// MARK: - HTTPClient
struct HTTPClient: Sendable, DependencyKey {
	let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	typealias ExecuteRequest = @Sendable (_ request: URLRequest, _ acceptedStatusCodes: [HTTPStatusCode]) async throws -> Data
}

extension HTTPClient {
	func executeRequest(_ request: URLRequest) async throws -> Data {
		try await executeRequest(request, [.ok])
	}
}
