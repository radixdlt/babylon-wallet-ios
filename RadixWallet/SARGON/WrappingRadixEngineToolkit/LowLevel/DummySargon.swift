import Foundation

// MARK: - DummySargon
public protocol DummySargon: Sendable, Equatable, Hashable {}

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
}
