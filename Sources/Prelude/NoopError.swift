// MARK: - NoopError
public struct NoopError: LocalizedError {
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

public extension NoopError {
	var errorDescription: String? {
		"\(message) in `\(file)`#\(line)"
	}
}
