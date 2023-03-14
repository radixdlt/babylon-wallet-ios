import Foundation

// MARK: - Enum
public struct Enum: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .enum
	public func embedValue() -> ManifestASTValue {
		.enum(self)
	}

	// MARK: Stored properties

	public let variant: EnumDiscriminator
	public let fields: [ManifestASTValue]

	// MARK: Init

	public init(_ variant: EnumDiscriminator) {
		self.variant = variant
		self.fields = []
	}

	public init(_ variant: EnumDiscriminator, fields: [ManifestASTValue]) {
		self.variant = variant
		self.fields = fields
	}

	public init(_ variant: String) {
		self.init(.string(variant))
	}

	public init(_ variant: String, fields: [ManifestASTValue]) {
		self.init(.string(variant), fields: fields)
	}

	public init(_ variant: UInt8) {
		self.init(.u8(variant))
	}

	public init(_ variant: UInt8, fields: [ManifestASTValue]) {
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
		@SpecificValuesBuilder fields: () throws -> [ManifestASTValue]
	) rethrows {
		try self.init(variant, fields: fields())
	}
}

extension Enum {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case variant
		case type
		case fields
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(variant, forKey: .variant)
		if !fields.isEmpty {
			try container.encode(fields, forKey: .fields)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			container.decode(EnumDiscriminator.self, forKey: .variant),
			fields: container.decodeIfPresent([ManifestASTValue].self, forKey: .fields) ?? []
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

extension EnumDiscriminator {
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

	public func encode(to encoder: Encoder) throws {
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

	public init(from decoder: Decoder) throws {
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
