// MARK: - Some
public struct Some: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ValueKind = .some
	public func embedValue() -> ManifestASTValue {
		.some(self)
	}

	// MARK: Stored properties

	public let value: ManifestASTValue

	public init(_ value: ManifestASTValue) {
		self.value = value
	}
}

extension Some {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type, value
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

		try self.init(container.decode(ManifestASTValue.self, forKey: .value))
	}
}
