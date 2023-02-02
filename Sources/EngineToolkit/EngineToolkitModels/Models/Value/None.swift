// MARK: - None
public struct None: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ValueKind = .none
	public func embedValue() -> Value_ {
		.none
	}
}

public extension None {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type, value
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.init()
	}
}
