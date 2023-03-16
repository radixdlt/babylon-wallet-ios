import Foundation

// MARK: - Expression
public struct Expression: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .expression
	public func embedValue() -> Value_ {
		.expression(self)
	}

	// MARK: Stored properties
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(value: value)
	}
}

extension Expression {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(value, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
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
