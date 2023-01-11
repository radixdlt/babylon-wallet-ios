import Foundation

// MARK: - TransientIdentifier
public enum TransientIdentifier: Sendable, Codable, Hashable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
	// ==============
	// Enum Variants
	// ==============
	case string(String)
	case u32(UInt32)
	public init(stringLiteral value: String) {
		self = .string(value)
	}

	public init(integerLiteral value: UInt32) {
		self = .u32(value)
	}
}

public extension TransientIdentifier {
	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container: SingleValueEncodingContainer = encoder.singleValueContainer()

		switch self {
		case let .string(string):
			try container.encode(string)
		case let .u32(id):
			try container.encode(id)
		}
	}

	init(from decoder: Decoder) throws {
		let value: SingleValueDecodingContainer = try decoder.singleValueContainer()
		do {
			let id: UInt32 = try value.decode(UInt32.self)
			self = .u32(id)
		} catch {
			let string: String = try value.decode(String.self)
			self = .string(string)
		}
	}
}
