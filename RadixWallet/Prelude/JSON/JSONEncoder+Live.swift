// MARK: - JSONEncoder + DependencyKey
extension JSONEncoder: DependencyKey {
	public typealias Value = @Sendable () -> JSONEncoder

	public static let liveValue = { @Sendable in
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}

	public static var previewValue: Value { liveValue }
	public static var testValue: Value { liveValue }
}

// MARK: - JSONEncoder + @unchecked Sendable
extension JSONEncoder: @unchecked Sendable {}

extension DependencyValues {
	var jsonEncoder: @Sendable () -> JSONEncoder {
		self[JSONEncoder.self]
	}
}
