import Foundation

// MARK: - U128
public struct U128: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .u128
	public func embedValue() -> Value_ {
		.u128(self)
	}

	// MARK: Stored properties
	// TODO: Swift does not have any 128-bit types, so, we store this as a string. We need a better solution to this.
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}

	public init(stringLiteral value: String) {
		self.init(value: value)
	}
}

public extension U128 {
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
		// TODO: Validation is needed here to ensure that this numeric and in the range of an Unsigned 128 bit number
		try self.init(value: container.decode(String.self, forKey: .value))
	}
}
