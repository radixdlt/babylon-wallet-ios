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

public extension TransientIdentifier {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
		case value
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .u32(value):
			try container.encode("U32", forKey: .type)
			try container.encode(String(value), forKey: .value)
		case let .string(value):
			try container.encode("String", forKey: .type)
			try container.encode(String(value), forKey: .value)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type value
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decode(String.self, forKey: .type)
		switch type {
		case "String":
			let value = try container.decode(String.self, forKey: .value)
			self = .string(value)
		case "U32":
			self = try .u32(decodeAndConvertToNumericType(container: container, key: .value))
		default:
			throw InternalDecodingFailure.parsingError
		}
	}
}
