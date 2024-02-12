import Foundation

// MARK: - DummySargon
public protocol DummySargon: Sendable, Equatable, Hashable, Codable, Identifiable, CustomStringConvertible {}

// MARK: - DeprecatedDummySargon
@available(*, deprecated, message: "Remove completely")
public protocol DeprecatedDummySargon: DummySargon {}

public func sargon(line: UInt = #line, file: StaticString = #file) -> Never {
	fatalError("Sargon migration: \(line), in \(file)")
}

extension DummySargon {
	public typealias ID = UUID
	public var id: ID {
		sargon()
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		sargon()
	}

	public func hash(into hasher: inout Hasher) {
		sargon()
	}

	public var description: String {
		sargon()
	}

	public func encode(to encoder: Encoder) throws {
		sargon()
	}

	public init(from decoder: Decoder) throws {
		sargon()
	}

	public func asStr() -> String {
		sargon()
	}
}

// MARK: - RadixEngineToolkitError
public struct RadixEngineToolkitError: DummySargon {}

// MARK: - BuildInformation
public struct BuildInformation: DummySargon {
	public let version: String
}
