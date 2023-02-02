// MARK: - Ok
public struct Ok: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ValueKind = .ok
	public func embedValue() -> Value_ {
		.ok(self)
	}

	// MARK: Stored properties

	public let value: Value_

	public init(_ value: Value_) {
		self.value = value
	}
}

public extension Ok {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type, value
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(value, forKey: .value)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(container.decode(Value_.self, forKey: .value))
	}
}
