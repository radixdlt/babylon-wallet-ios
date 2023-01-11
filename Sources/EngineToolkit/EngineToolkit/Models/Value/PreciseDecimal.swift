import Foundation

// MARK: - PreciseDecimal
public struct PreciseDecimal: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .preciseDecimal
	public func embedValue() -> Value_ {
		.preciseDecimal(self)
	}

	// MARK: Stored properties
	// TODO: Convert this to a better numerical type
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}

	public init(integerLiteral value: Int) {
		self.init(value: "\(value)")
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(value: value)
	}

	// FIXME: investigate which `Locale` is being used here.. might need to use `NumberFormatter`, i.e.
	// does `"\(value)"` use "," or "." for decimals, and what does Scrypto expect?
	public init(floatLiteral value: Double) {
		self.init(value: "\(value)")
	}
}

public extension PreciseDecimal {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(String(value), forKey: .value)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `value`
		try self.init(value: container.decode(String.self, forKey: .value))
	}
}
