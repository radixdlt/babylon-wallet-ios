import CasePaths
import Foundation

// MARK: - ValueProtocol
public protocol ValueProtocol {
	static var kind: ManifestASTValueKind { get }
	static var casePath: CasePath<ManifestASTValue, Self> { get }
}

extension ValueProtocol {
	public var kind: ManifestASTValueKind { Self.kind }
	public var casePath: CasePath<ManifestASTValue, Self> { Self.casePath }
}

extension ValueProtocol {
	public func embedValue() -> ManifestASTValue {
		casePath.embed(self)
	}

	public static func extractValue(from value: ManifestASTValue) throws -> Self {
		guard let extracted = casePath.extract(from: value) else {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: value.kind)
		}
		return extracted
	}
}

// MARK: - ManifestASTValue
public indirect enum ManifestASTValue: Sendable, Codable, Hashable {
	// ==============
	// Enum Variants
	// ==============

	case boolean(Bool)

	case i8(Int8)
	case i16(Int16)
	case i32(Int32)
	case i64(Int64)
	case i128(I128)

	case u8(UInt8)
	case u16(UInt16)
	case u32(UInt32)
	case u64(UInt64)
	case u128(U128)

	case string(String)

	case `enum`(Enum)

	case some(Some)
	case none
	case ok(Ok)
	case err(Err)

	case array(Array_)
	case tuple(Tuple)
	case map(Map_)

	case decimal(Decimal_)
	case preciseDecimal(PreciseDecimal)

	// case own(Own) // Not implemented and commented out because it isn't supported to well by Scrypto

	case address(Address)

	case bucket(Bucket)
	case proof(Proof)

	case nonFungibleLocalId(NonFungibleLocalId)
	case nonFungibleGlobalId(NonFungibleGlobalId)

	case blob(Blob)
	case expression(ManifestExpression)
	case bytes(Bytes)
}

// MARK: - ModelValueKind
public protocol ModelValueKind: Sendable {
	static var kind: ManifestASTValueKind { get }
}

extension ManifestASTValue {
	// ===========
	// Value Kind
	// ===========

	public var kind: ManifestASTValueKind {
		switch self {
		case .boolean:
			return .bool

		case .i8:
			return .i8

		case .i16:
			return .i16

		case .i32:
			return .i32

		case .i64:
			return .i64

		case .i128:
			return .i128

		case .u8:
			return .u8

		case .u16:
			return .u16

		case .u32:
			return .u32

		case .u64:
			return .u64

		case .u128:
			return .u128

		case .string:
			return .string

		case .enum:
			return .enum
		case .some:
			return .some
		case .none:
			return .none
		case .ok:
			return .ok
		case .err:
			return .err

		case .array:
			return .array
		case .tuple:
			return .tuple
		case .map:
			return .map

		case .decimal:
			return .decimal

		case .preciseDecimal:
			return .preciseDecimal

		case .address:
			return .address

		case .bucket:
			return .bucket
		case .proof:
			return .proof

		case .nonFungibleLocalId:
			return .nonFungibleLocalId

		case .nonFungibleGlobalId:
			return .nonFungibleGlobalId

		case .blob:
			return .blob

		case .expression:
			return .expression
		case .bytes:
			return .bytes
		}
	}
}

extension ManifestASTValue {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case kind
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(kind, forKey: .kind)

		switch self {
		case let .boolean(value):
			try ValueCodable(value).encode(to: encoder)

		case let .i8(value):
			try IntegerCodable(value).encode(to: encoder)

		case let .i16(value):
			// `Int16` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .i32(value):
			// `Int32` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .i64(value):
			// `Int64` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .i128(value):
			try ValueCodable(value).encode(to: encoder)

		case let .u8(value):
			// `UInt8` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .u16(value):
			// `UInt16` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .u32(value):
			// `UInt32` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .u64(value):
			// `UInt64` is already `Codable` so we have to go through its proxy type for JSON coding.
			try IntegerCodable(value).encode(to: encoder)

		case let .u128(value):
			try ValueCodable(value).encode(to: encoder)

		case let .string(value):
			// `String` is already `Codable` so we have to go through its proxy type for JSON coding.
			try ValueCodable(value).encode(to: encoder)

		case let .enum(value):
			try value.encode(to: encoder)

		case let .some(value):
			try ValueCodable(value).encode(to: encoder)
		case .none:
			break
		case let .ok(value):
			try ValueCodable(value).encode(to: encoder)
		case let .err(value):
			try ValueCodable(value).encode(to: encoder)

		case let .array(value):
			try value.encode(to: encoder)

		case let .tuple(value):
			try value.encode(to: encoder)

		case let .map(value):
			try value.encode(to: encoder)

		case let .decimal(value):
			try ValueCodable(value).encode(to: encoder)

		case let .preciseDecimal(value):
			try ValueCodable(value).encode(to: encoder)

		case let .address(value):
			try ValueCodable(value).encode(to: encoder)

		case let .bucket(value):
			try ValueCodable(value).encode(to: encoder)

		case let .proof(value):
			try ValueCodable(value).encode(to: encoder)

		case let .nonFungibleLocalId(value):
			try ValueCodable(value).encode(to: encoder)

		case let .nonFungibleGlobalId(value):
			try value.encode(to: encoder)

		case let .blob(value):
			try ValueCodable(value).encode(to: encoder)

		case let .expression(value):
			try ValueCodable(value).encode(to: encoder)
		case let .bytes(value):
			try value.encode(to: encoder)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)

		switch kind {
		case .bool:
			self = try .boolean(ValueCodable(from: decoder).value)

		case .i8:
			self = try .i8(IntegerCodable(from: decoder).value)

		case .i16:
			// `Int16` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i16(IntegerCodable(from: decoder).value)

		case .i32:
			// `Int32` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i32(IntegerCodable(from: decoder).value)

		case .i64:
			// `Int64` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i64(IntegerCodable(from: decoder).value)

		case .i128:
			self = try .i128(ValueCodable(from: decoder).value)

		case .u8:
			// `UInt8` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u8(IntegerCodable(from: decoder).value)

		case .u16:
			// `UInt16` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u16(IntegerCodable(from: decoder).value)

		case .u32:
			// `UInt32` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u32(IntegerCodable(from: decoder).value)

		case .u64:
			// `UInt64` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u64(IntegerCodable(from: decoder).value)

		case .u128:
			self = try .u128(ValueCodable(from: decoder).value)

		case .string:
			// `String` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .string(ValueCodable(from: decoder).value)

		case .enum:
			self = try .enum(.init(from: decoder))

		case .some:
			self = try .some(ValueCodable(from: decoder).value)
		case .none:
			self = .none
		case .ok:
			self = try .ok(ValueCodable(from: decoder).value)
		case .err:
			self = try .err(ValueCodable(from: decoder).value)

		case .array:
			self = try .array(.init(from: decoder))

		case .tuple:
			self = try .tuple(.init(from: decoder))

		case .map:
			self = try .map(.init(from: decoder))

		case .decimal:
			self = try .decimal(ValueCodable(from: decoder).value)

		case .preciseDecimal:
			self = try .preciseDecimal(ValueCodable(from: decoder).value)

		case .address:
			self = try .address(ValueCodable(from: decoder).value)

		case .bucket:
			self = try .bucket(ValueCodable(from: decoder).value)

		case .proof:
			self = try .proof(ValueCodable(from: decoder).value)

		case .nonFungibleLocalId:
			self = try .nonFungibleLocalId(ValueCodable(from: decoder).value)

		case .nonFungibleGlobalId:
			self = try .nonFungibleGlobalId(.init(from: decoder))

		case .blob:
			self = try .blob(ValueCodable(from: decoder).value)

		case .expression:
			self = try .expression(ValueCodable(from: decoder).value)

		case .bytes:
			self = try .bytes(.init(from: decoder))
		}
	}
}
