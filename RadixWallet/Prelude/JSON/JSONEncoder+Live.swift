// MARK: - JSONEncoder + @retroactive DependencyKey
extension JSONEncoder: @retroactive DependencyKey {
	public typealias Value = @Sendable () -> JSONEncoder

	public static let liveValue = { @Sendable in
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		return encoder
	}

	public static var previewValue: Value { liveValue }
	public static var testValue: Value { liveValue }
}

extension DependencyValues {
	var jsonEncoder: @Sendable () -> JSONEncoder {
		self[JSONEncoder.self]
	}
}
