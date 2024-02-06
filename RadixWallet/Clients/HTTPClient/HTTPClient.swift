// MARK: - HTTPClient
public struct HTTPClient: Sendable, DependencyKey {
	public let executeRequest: ExecuteRequest
}

// MARK: HTTPClient.ExecuteRequest
extension HTTPClient {
	public typealias ExecuteRequest = @Sendable (URLRequest) async throws -> Data
}

extension HTTPClient {
	public static let liveValue: HTTPClient = {
		let session = URLSession.shared

		return .init(
			executeRequest: { request in
				let (data, urlResponse) = try await session.data(for: request)

				guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
					throw ExpectedHTTPURLResponse()
				}

				guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
					#if DEBUG
					loggerGlobal.error("Request with URL: \(request.url!.absoluteString) failed with status code: \(httpURLResponse.statusCode), data: \(data.prettyPrintedJSONString ?? "<NOT_JSON>")")
					#endif
					throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
				}

				return data
			}
		)
	}()
}

extension DependencyValues {
	public var httpClient: HTTPClient {
		get { self[HTTPClient.self] }
		set { self[HTTPClient.self] = newValue }
	}
}
