import Foundation

// MARK: - Decimal_
public struct Decimal_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .decimal
	public func embedValue() -> Value_ {
		.decimal(self)
	}

	// MARK: Stored properties
	// TODO: Convert this to a better numerical type
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}
}

extension Decimal_ {
	private var string: String {
		value
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(string, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `value`
		let string = try container.decode(String.self, forKey: .value)
		self.init(value: string)
	}
}
