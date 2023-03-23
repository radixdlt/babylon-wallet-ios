// MARK: - HashRequest
public struct HashRequest: Sendable, Codable, Hashable {
	public let payload: String

	public init(payload: String) {
		self.payload = payload
	}
}

// MARK: - HashResponse
public struct HashResponse: Sendable, Codable, Hashable {
	public let value: String

	public init(value: String) {
		self.value = value
	}
}
