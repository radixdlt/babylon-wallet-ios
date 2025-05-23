// MARK: - JSONDecoder + DependencyKey
extension JSONDecoder: DependencyKey {
	public typealias Value = @Sendable () -> JSONDecoder

	public static let liveValue = { @Sendable in
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}

	public static var previewValue: Value { liveValue }
	public static var testValue: Value { liveValue }
}

// MARK: - JSONDecoder + @unchecked Sendable
extension JSONDecoder: @unchecked Sendable {}

extension DependencyValues {
	var jsonDecoder: @Sendable () -> JSONDecoder {
		self[JSONDecoder.self]
	}
}
