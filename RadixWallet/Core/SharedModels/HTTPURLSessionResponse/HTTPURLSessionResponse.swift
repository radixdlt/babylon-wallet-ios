// MARK: - ExpectedHTTPURLResponse
struct ExpectedHTTPURLResponse: Swift.Error {
	init() {}
}

// MARK: - RequestRetryAttemptsExceeded
struct RequestRetryAttemptsExceeded: Swift.Error {
	init() {}
}

// MARK: - BadHTTPResponseCode
struct BadHTTPResponseCode: LocalizedError {
	let got: Int

	init(got: Int) {
		self.got = got
	}

	var errorDescription: String? {
		switch got {
		case 429:
			L10n.Common.rateLimitReached
		default:
			L10n.Common.badHttpResponseStatusCode(got)
		}
	}
}

// MARK: - ResponseDecodingError
struct ResponseDecodingError: Swift.Error {
	let receivedData: Data
	let error: Error

	init(receivedData: Data, error: Error) {
		self.receivedData = receivedData
		self.error = error
	}
}

// MARK: - HTTPStatusCode
enum HTTPStatusCode: Int, Error {
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
