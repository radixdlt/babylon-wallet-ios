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

// MARK: - HashTransactionIntentResponse
public struct HashTransactionIntentResponse: Codable, Equatable {
	public let hash: String
}

// MARK: - HashNotarizedTransactionResponse
public struct HashNotarizedTransactionResponse: Codable, Equatable {
	public let hash: String
}

// MARK: - HashSignedTransactionItentResponse
public struct HashSignedTransactionItentResponse: Codable, Equatable {
	public let hash: String
}
