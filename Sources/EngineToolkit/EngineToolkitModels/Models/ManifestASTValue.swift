import Foundation

// MARK: - ValueProtocol
public protocol ValueProtocol {
	static var kind: ManifestASTValueKind { get }
	func embedValue() -> ManifestASTValue
}

extension ValueProtocol {
	public var kind: ManifestASTValueKind { Self.kind }
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

	case integer(Int)
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

	case address(Address_)

	case bucket(Bucket)
	case proof(Proof)

	case nonFungibleLocalId(NonFungibleLocalId)
	case nonFungibleGlobalId(NonFungibleGlobalId)

	case blob(Blob)
	case expression(Expression)
	case bytes(Bytes)
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
		case .integer:
			return .integer
		}
	}
}

extension ManifestASTValue {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .boolean(value):
			// `Bool` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .i8(value):
			// `Int8` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .i16(value):
			// `Int16` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .i32(value):
			// `Int32` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .i64(value):
			// `Int64` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .i128(value):
			try value.encode(to: encoder)

		case let .u8(value):
			// `UInt8` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .u16(value):
			// `UInt16` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .u32(value):
			// `UInt32` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .u64(value):
			// `UInt64` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .u128(value):
			try value.encode(to: encoder)

		case let .string(value):
			// `String` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)

		case let .enum(value):
			try value.encode(to: encoder)
		case let .some(value):
			try value.encode(to: encoder)
		case .none:
			try None().encode(to: encoder)
		case let .ok(value):
			try value.encode(to: encoder)
		case let .err(value):
			try value.encode(to: encoder)

		case let .array(value):
			try value.encode(to: encoder)

		case let .tuple(value):
			try value.encode(to: encoder)

		case let .map(value):
			try value.encode(to: encoder)

		case let .decimal(value):
			try value.encode(to: encoder)

		case let .preciseDecimal(value):
			try value.encode(to: encoder)

		case let .address(value):
			try value.encode(to: encoder)

		case let .bucket(value):
			try value.encode(to: encoder)

		case let .proof(value):
			try value.encode(to: encoder)

		case let .nonFungibleLocalId(value):
			try value.encode(to: encoder)

		case let .nonFungibleGlobalId(value):
			try value.encode(to: encoder)

		case let .blob(value):
			try value.encode(to: encoder)

		case let .expression(value):
			try value.encode(to: encoder)
		case let .bytes(value):
			try value.encode(to: encoder)
		case let .integer(value):
			try value.encode(to: encoder)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .type)

		switch kind {
		case .bool:
			// `Bool` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .boolean(Bool.ProxyDecodable(from: decoder).decoded)

		case .i8:
			// `Int8` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i8(Int8.ProxyDecodable(from: decoder).decoded)

		case .i16:
			// `Int16` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i16(Int16.ProxyDecodable(from: decoder).decoded)

		case .i32:
			// `Int32` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i32(Int32.ProxyDecodable(from: decoder).decoded)

		case .i64:
			// `Int64` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .i64(Int64.ProxyDecodable(from: decoder).decoded)

		case .i128:
			self = try .i128(.init(from: decoder))

		case .u8:
			// `UInt8` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u8(UInt8.ProxyDecodable(from: decoder).decoded)

		case .u16:
			// `UInt16` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u16(UInt16.ProxyDecodable(from: decoder).decoded)

		case .u32:
			// `UInt32` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u32(UInt32.ProxyDecodable(from: decoder).decoded)

		case .u64:
			// `UInt64` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .u64(UInt64.ProxyDecodable(from: decoder).decoded)

		case .u128:
			self = try .u128(.init(from: decoder))

		case .string:
			// `String` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .string(String.ProxyDecodable(from: decoder).decoded)

		case .enum:
			self = try .enum(.init(from: decoder))

		case .some:
			self = try .some(.init(from: decoder))
		case .none:
			self = .none
		case .ok:
			self = try .ok(.init(from: decoder))
		case .err:
			self = try .err(.init(from: decoder))

		case .array:
			self = try .array(.init(from: decoder))

		case .tuple:
			self = try .tuple(.init(from: decoder))

		case .map:
			self = try .map(.init(from: decoder))

		case .decimal:
			self = try .decimal(.init(from: decoder))

		case .preciseDecimal:
			self = try .preciseDecimal(.init(from: decoder))

		case .address:
			self = try .address(.init(from: decoder))

		case .bucket:
			self = try .bucket(.init(from: decoder))

		case .proof:
			self = try .proof(.init(from: decoder))

		case .nonFungibleLocalId:
			self = try .nonFungibleLocalId(.init(from: decoder))

		case .nonFungibleGlobalId:
			self = try .nonFungibleGlobalId(.init(from: decoder))

		case .blob:
			self = try .blob(.init(from: decoder))

		case .expression:
			self = try .expression(.init(from: decoder))

		case .bytes:
			self = try .bytes(.init(from: decoder))
		case .integer:
			self = try .integer(.init(from: decoder))
		}
	}
}
