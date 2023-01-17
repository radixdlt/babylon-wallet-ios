import Foundation

// MARK: - IdentifierConvertible
public protocol IdentifierConvertible: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
	var identifier: TransientIdentifier { get }
	init(identifier: TransientIdentifier)
}

public extension IdentifierConvertible {
	init(_ identifier: TransientIdentifier) {
		self.init(identifier: identifier)
	}

	init(identifier: String) {
		self.init(identifier: .string(identifier))
	}

	init(identifier: UInt32) {
		self.init(identifier: .u32(identifier))
	}

	init(stringLiteral value: String) {
		self.init(identifier: value)
	}

	init(integerLiteral value: UInt32) {
		self.init(identifier: value)
	}
}
