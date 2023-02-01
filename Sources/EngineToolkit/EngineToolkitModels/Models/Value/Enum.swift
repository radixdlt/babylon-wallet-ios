import Foundation

// MARK: - Enum
public struct Enum: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .enum
	public func embedValue() -> Value_ {
		.enum(self)
	}

	// MARK: Stored properties

	public let variant: EnumDiscriminator
	public let fields: [Value_]

	// MARK: Init

	public init(_ variant: EnumDiscriminator) {
		self.variant = variant
		self.fields = []
	}

	public init(_ variant: EnumDiscriminator, fields: [Value_]) {
		self.variant = variant
		self.fields = fields
	}

	public init(_ variant: String) {
		self.init(.string(variant))
	}

	public init(_ variant: String, fields: [Value_]) {
		self.init(.string(variant), fields: fields)
	}

	public init(_ variant: UInt8) {
		self.init(.u8(variant))
	}

	public init(_ variant: UInt8, fields: [Value_]) {
		self.init(.u8(variant), fields: fields)
	}

	public init(
		_ variant: EnumDiscriminator,
		@ValuesBuilder fields: () throws -> [ValueProtocol]
	) rethrows {
		try self.init(variant, fields: fields().map { $0.embedValue() })
	}

	public init(
		_ variant: EnumDiscriminator,
		@SpecificValuesBuilder fields: () throws -> [Value_]
	) rethrows {
		try self.init(variant, fields: fields())
	}
}

public extension Enum {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case variant
		case type
		case fields
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(variant, forKey: .variant)
		try container.encode(fields, forKey: .fields)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			container.decode(EnumDiscriminator.self, forKey: .variant),
			fields: container.decodeIfPresent([Value_].self, forKey: .fields) ?? []
		)
	}
}

// MARK: - EnumDiscriminator
public enum EnumDiscriminator: Sendable, Codable, Hashable {
	case string(String)
	case u8(UInt8)

	// MARK: Init

	public init(_ discriminator: String) {
		self = .string(discriminator)
	}

	public init(_ discriminator: UInt8) {
		self = .u8(discriminator)
	}
}

public extension EnumDiscriminator {
	private enum Kind: String, Codable {
		case u8 = "U8"
		case string = "String"
	}

	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
		case discriminator
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .u8(discriminator):
			try container.encode(Kind.u8, forKey: .type)
			try container.encode(String(discriminator), forKey: .discriminator)
		case let .string(discriminator):
			try container.encode(Kind.string, forKey: .type)
			try container.encode(String(discriminator), forKey: .discriminator)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decode(Kind.self, forKey: .type)
		switch type {
		case .u8:
			self = try .u8(decodeAndConvertToNumericType(container: container, key: .discriminator))
		case .string:
			self = try .string(container.decode(String.self, forKey: .discriminator))
		}
	}
}
