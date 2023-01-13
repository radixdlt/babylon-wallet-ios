import Foundation

// MARK: - NonFungibleId
public enum NonFungibleId {
	case u32(UInt32)
	case u64(UInt64)
	case uuid(String)
	case string(String)
	case bytes([UInt8])
}

// MARK: NonFungibleId.Kind
public extension NonFungibleId {
	// MARK: Kind
	enum Kind: String, Codable {
		case u32 = "U32"
		case u64 = "U64"
		case uuid = "UUID"
		case string = "String"
		case bytes = "Bytes"
	}
}

// MARK: ValueProtocol, Sendable, Codable, Hashable
extension NonFungibleId: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .nonFungibleId
	public func embedValue() -> Value_ {
		.nonFungibleId(self)
	}
}

public extension NonFungibleId {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type, variant
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		switch self {
		case let .u32(identifier):
			try container.encode(Kind.u32, forKey: .variant)
			try container.encode(String(identifier), forKey: .value)
		case let .u64(identifier):
			try container.encode(Kind.u64, forKey: .variant)
			try container.encode(String(identifier), forKey: .value)
		case let .uuid(identifier):
			try container.encode(Kind.uuid, forKey: .variant)
			try container.encode(String(identifier), forKey: .value)
		case let .string(identifier):
			try container.encode(Kind.string, forKey: .variant)
			try container.encode(identifier, forKey: .value)
		case let .bytes(identifier):
			try container.encode(Kind.bytes, forKey: .variant)
			try container.encode(identifier.hex(), forKey: .value)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let variant = try container.decode(Kind.self, forKey: .variant)
		switch variant {
		case .u32:
			self = .u32(try decodeAndConvertToNumericType(container: container, key: .value))
		case .u64:
			self = .u64(try decodeAndConvertToNumericType(container: container, key: .value))
		case .uuid:
			self = .uuid(try container.decode(String.self, forKey: .value))
		case .string:
			self = .string(try container.decode(String.self, forKey: .value))
		case .bytes:
			self = try .bytes(.init(hex: container.decode(String.self, forKey: .value)))
		}
	}
}
