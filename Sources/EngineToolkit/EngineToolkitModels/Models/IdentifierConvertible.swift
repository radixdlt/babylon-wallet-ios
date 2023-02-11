import Foundation

// MARK: - IdentifierConvertible
public protocol IdentifierConvertible: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
	var identifier: TransientIdentifier { get }
	init(identifier: TransientIdentifier)
}

extension IdentifierConvertible {
	public init(_ identifier: TransientIdentifier) {
		self.init(identifier: identifier)
	}

	public init(identifier: String) {
		self.init(identifier: .string(identifier))
	}

	public init(identifier: UInt32) {
		self.init(identifier: .u32(identifier))
	}

	public init(stringLiteral value: String) {
		self.init(identifier: value)
	}

	public init(integerLiteral value: UInt32) {
		self.init(identifier: value)
	}
}
