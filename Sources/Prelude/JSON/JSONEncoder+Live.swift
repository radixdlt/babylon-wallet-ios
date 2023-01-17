import Dependencies

// MARK: - JSONEncoder + DependencyKey
extension JSONEncoder: DependencyKey {
	public typealias Value = @Sendable () -> JSONEncoder

	public static let liveValue = { @Sendable in
		let decoder = JSONEncoder()
		decoder.dateEncodingStrategy = .iso8601
		return decoder
	}

	public static var previewValue: Value { liveValue }
	public static var testValue: Value { liveValue }
}

// MARK: - JSONEncoder + Sendable
extension JSONEncoder: @unchecked Sendable {}

public extension DependencyValues {
	var jsonEncoder: @Sendable () -> JSONEncoder {
		self[JSONEncoder.self]
	}
}
