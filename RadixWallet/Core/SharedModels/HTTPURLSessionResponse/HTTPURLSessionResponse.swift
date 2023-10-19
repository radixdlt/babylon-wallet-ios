// MARK: - ExpectedHTTPURLResponse
public struct ExpectedHTTPURLResponse: Swift.Error {
	public init() {}
}

// MARK: - BadHTTPResponseCode
public struct BadHTTPResponseCode: Swift.Error {
	public let got: Int
	public let butExpected = Self.expected
	public static let expected = 200

	public init(got: Int) {
		self.got = got
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
