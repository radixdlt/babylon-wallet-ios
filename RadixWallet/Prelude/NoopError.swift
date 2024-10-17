// MARK: - NoopError
struct NoopError {
	let message: String
	let file: StaticString
	let line: UInt

	init(
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
	var errorDescription: String? {
		"\(message) in `\(file)`#\(line)"
	}
}

// MARK: Equatable
extension NoopError: Equatable {
	static func == (lhs: NoopError, rhs: NoopError) -> Bool {
		lhs.message == rhs.message
	}
}
