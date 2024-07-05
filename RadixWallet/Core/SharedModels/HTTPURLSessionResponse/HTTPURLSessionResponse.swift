// MARK: - ExpectedHTTPURLResponse
public struct ExpectedHTTPURLResponse: Swift.Error {
	public init() {}
}

// MARK: - BadHTTPResponseCode
public struct BadHTTPResponseCode: LocalizedError {
	public let got: Int

	public init(got: Int) {
		self.got = got
	}

	public var errorDescription: String? {
		switch got {
		case 429:
			L10n.Common.rateLimitReached
		default:
			L10n.Common.badHttpResponseStatusCode(got)
		}
	}
}

// MARK: - ResponseDecodingError
public struct ResponseDecodingError: Swift.Error {
	public let receivedData: Data
	public let error: Error

	public init(receivedData: Data, error: Error) {
		self.receivedData = receivedData
		self.error = error
	}
}

// MARK: - HTTPStatusCode
public enum HTTPStatusCode: Int, Error {
    /// - ok: Standard response for successful HTTP requests.
    case ok = 200
    
    /// - accepted: The request has been accepted for processing, but the processing has not been completed.
    case accepted = 202
}

extension HTTPURLResponse {
	var status: HTTPStatusCode? {
		.init(rawValue: statusCode)
	}
}
