import Foundation

// MARK: - DummySargon
public protocol DummySargon: Sendable, Equatable, Hashable, Codable {}

public func sargon(line: UInt = #line, file: StaticString = #file) -> Never {
	fatalError("Sargon migration: \(line), in \(file)")
}

extension DummySargon {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		sargon()
	}

	public func hash(into hasher: inout Hasher) {
		sargon()
	}

	public func encode(to encoder: Encoder) throws {
		sargon()
	}

	public init(from decoder: Decoder) throws {
		sargon()
	}
}
