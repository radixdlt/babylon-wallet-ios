import Foundation

// MARK: - Supply
public enum Supply: Sendable, Equatable {
	case fixed(UInt256)
	case mutable(lastKnown: UInt256)
}

// MARK: - UInt256
public struct UInt256: Sendable, Equatable, ExpressibleByIntegerLiteral {
	public let magnitude: UInt64 // TODO: replace me

	public init(magnitude: UInt64) {
		self.magnitude = magnitude
	}

	public init(integerLiteral value: IntegerLiteralType) {
		self.init(magnitude: UInt64(value))
	}
}
