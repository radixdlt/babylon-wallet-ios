// MARK: - TransientIdentifier
public enum TransientIdentifier: Sendable, Codable, Hashable {
	case string(String)
	case u32(UInt32)

	// MARK: Init

	public init(_ value: String) {
		self = .string(value)
	}

	public init(_ value: UInt32) {
		self = .u32(value)
	}
}

extension TransientIdentifier {
	private enum Kind: String, Codable {
		case u32 = "U32"
		case string = "String"
	}

	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
		case value
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .u32(value):
			try container.encode(Kind.u32, forKey: .type)
			try container.encode(String(value), forKey: .value)
		case let .string(value):
			try container.encode(Kind.string, forKey: .type)
			try container.encode(String(value), forKey: .value)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type value
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decode(Kind.self, forKey: .type)
		switch type {
		case .u32:
			self = try .u32(decodeAndConvertToNumericType(container: container, key: .value))
		case .string:
			self = try .string(container.decode(String.self, forKey: .value))
		}
	}
}
