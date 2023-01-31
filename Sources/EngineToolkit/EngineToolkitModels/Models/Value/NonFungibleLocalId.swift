import Foundation

// MARK: - NonFungibleLocalId
public enum NonFungibleLocalId {
	case integer(UInt64)
	case uuid(String)
	case string(String)
	case bytes([UInt8])
}

// MARK: ValueProtocol, Sendable, Codable, Hashable
extension NonFungibleLocalId: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .nonFungibleLocalId
	public func embedValue() -> Value_ {
		.nonFungibleLocalId(self)
	}

	private init(internal_value: NonFungibleLocalIdInternal) {
		switch internal_value {
		case let .integer(value):
			self = .integer(value)
		case let .string(value):
			self = .string(value)
		case let .uuid(value):
			self = .uuid(value)
		case let .bytes(value):
			self = .bytes(value)
		}
	}

	private func toInternal() -> NonFungibleLocalIdInternal {
		switch self {
		case let .integer(value):
			return .integer(value)
		case let .string(value):
			return .string(value)
		case let .uuid(value):
			return .uuid(value)
		case let .bytes(value):
			return .bytes(value)
		}
	}
}

public extension NonFungibleLocalId {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(self.toInternal(), forKey: .value)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let internal_value = try container.decode(NonFungibleLocalIdInternal.self, forKey: .value)
		self.init(internal_value: internal_value)
	}
}

// MARK: - NonFungibleLocalIdInternal
private enum NonFungibleLocalIdInternal: Sendable, Codable, Hashable {
	case integer(UInt64)
	case uuid(String)
	case string(String)
	case bytes([UInt8])

	enum Kind: String, Codable {
		case integer = "Integer"
		case uuid = "UUID"
		case string = "String"
		case bytes = "Bytes"
	}
}

private extension NonFungibleLocalIdInternal {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .integer(identifier):
			try container.encode(Kind.integer, forKey: .type)
			try container.encode(String(identifier), forKey: .value)
		case let .uuid(identifier):
			try container.encode(Kind.uuid, forKey: .type)
			try container.encode(String(identifier), forKey: .value)
		case let .string(identifier):
			try container.encode(Kind.string, forKey: .type)
			try container.encode(identifier, forKey: .value)
		case let .bytes(identifier):
			try container.encode(Kind.bytes, forKey: .type)
			try container.encode(identifier.hex(), forKey: .value)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let value = try container.decode(Kind.self, forKey: .type)
		switch value {
		case .integer:
			self = .integer(try decodeAndConvertToNumericType(container: container, key: .value))
		case .uuid:
			self = .uuid(try container.decode(String.self, forKey: .value))
		case .string:
			self = .string(try container.decode(String.self, forKey: .value))
		case .bytes:
			self = try .bytes(.init(hex: container.decode(String.self, forKey: .value)))
		}
	}
}
