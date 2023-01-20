import Foundation

public func with<T>(
	_ initial: T,
	update: (inout T) throws -> Void
) rethrows -> T {
	var value = initial
	try update(&value)
	return value
}

// MARK: - ToldToFail
struct NoopError: LocalizedError {
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

	var errorDescription: String? {
		"\(message) in `\(file)`#\(line)"
	}
}

public func fail<T>(
	_ msg: String? = nil,
	file: StaticString = #filePath,
	line: UInt = #line
) throws -> T {
	throw ToldToFail(msg, file: file, line: line)
}
