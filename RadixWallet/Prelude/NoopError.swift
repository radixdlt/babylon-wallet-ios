// MARK: - NoopError
public struct NoopError {
	public let message: String
	public let file: StaticString
	public let line: UInt

	public init(
		_ msg: String? = nil,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		self.message = msg.map { "\(Self.self) - \($0)" } ?? "\(Self.self)"
		self.file = file
		self.line = line
	}
}

// MARK: LocalizedError
extension NoopError: LocalizedError {
	public var errorDescription: String? {
		"\(message) in `\(file)`#\(line)"
	}
}

// MARK: Equatable
extension NoopError: Equatable {
	public static func == (lhs: NoopError, rhs: NoopError) -> Bool {
		lhs.message == rhs.message
	}
}
