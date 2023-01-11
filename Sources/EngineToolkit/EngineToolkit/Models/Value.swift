import Foundation

// MARK: - ValueProtocol
public protocol ValueProtocol {
	static var kind: ValueKind { get }
	func embedValue() -> Value_
}

public extension ValueProtocol {
	var kind: ValueKind { Self.kind }
}

// MARK: - Value_
public indirect enum Value_: Sendable, Codable, Hashable {
	// ==============
	// Enum Variants
	// ==============

	case unit(Unit)
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

	case option(Value_?)
	case result(Result<Value_, Value_>)
	case array(Array_)
	case tuple(Tuple)

	case decimal(Decimal_)
	case preciseDecimal(PreciseDecimal)

	case component(Component)
	case packageAddress(PackageAddress)
	case componentAddress(ComponentAddress)
	case resourceAddress(ResourceAddress)
	case systemAddress(SystemAddress)

	case hash(Hash)

	case bucket(Bucket)
	case proof(Proof)
	case vault(Vault)

	case nonFungibleId(NonFungibleId)
	case nonFungibleAddress(NonFungibleAddress)

	case keyValueStore(KeyValueStore)

	case ecdsaSecp256k1PublicKey(EcdsaSecp256k1PublicKey)
	case ecdsaSecp256k1Signature(EcdsaSecp256k1Signature)
	case eddsaEd25519PublicKey(EddsaEd25519PublicKey)
	case eddsaEd25519Signature(EddsaEd25519Signature)

	case blob(Blob)
	case expression(Expression)
	case bytes(Bytes)
}

public extension Value_ {
	// ===========
	// Value Kind
	// ===========

	var kind: ValueKind {
		switch self {
		case .unit:
			return .unit

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
		case .option:
			return .option
		case .result:
			return .result

		case .array:
			return .array

		case .tuple:
			return .tuple

		case .decimal:
			return .decimal

		case .preciseDecimal:
			return .preciseDecimal

		case .component:
			return .component

		case .packageAddress:
			return .packageAddress

		case .componentAddress:
			return .componentAddress

		case .resourceAddress:
			return .resourceAddress

		case .systemAddress:
			return .systemAddress

		case .hash:
			return .hash

		case .bucket:
			return .bucket
		case .proof:
			return .proof
		case .vault:
			return .vault

		case .nonFungibleId:
			return .nonFungibleId

		case .nonFungibleAddress:
			return .nonFungibleAddress

		case .keyValueStore:
			return .keyValueStore

		case .ecdsaSecp256k1PublicKey:
			return .ecdsaSecp256k1PublicKey

		case .ecdsaSecp256k1Signature:
			return .ecdsaSecp256k1Signature

		case .eddsaEd25519PublicKey:
			return .eddsaEd25519PublicKey

		case .eddsaEd25519Signature:
			return .eddsaEd25519Signature

		case .blob:
			return .blob

		case .expression:
			return .expression
		case .bytes:
			return .bytes
		}
	}
}

public extension Value_ {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .unit(value):
			try value.encode(to: encoder)

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
		case let .option(value):
			// `Optional` is already `Codable` so we have to go through its proxy type for JSON coding.
			try value.proxyEncodable.encode(to: encoder)
		case let .result(value):
			try value.encode(to: encoder)

		case let .array(value):
			try value.encode(to: encoder)

		case let .tuple(value):
			try value.encode(to: encoder)

		case let .decimal(value):
			try value.encode(to: encoder)

		case let .preciseDecimal(value):
			try value.encode(to: encoder)

		case let .component(value):
			try value.encode(to: encoder)

		case let .packageAddress(value):
			try value.encode(to: encoder)

		case let .componentAddress(value):
			try value.encode(to: encoder)

		case let .resourceAddress(value):
			try value.encode(to: encoder)

		case let .systemAddress(value):
			try value.encode(to: encoder)

		case let .hash(value):
			try value.encode(to: encoder)

		case let .bucket(value):
			try value.encode(to: encoder)

		case let .proof(value):
			try value.encode(to: encoder)

		case let .vault(value):
			try value.encode(to: encoder)

		case let .nonFungibleId(value):
			try value.encode(to: encoder)

		case let .nonFungibleAddress(value):
			try value.encode(to: encoder)

		case let .keyValueStore(value):
			try value.encode(to: encoder)

		case let .ecdsaSecp256k1PublicKey(value):
			try value.encode(to: encoder)

		case let .ecdsaSecp256k1Signature(value):
			try value.encode(to: encoder)

		case let .eddsaEd25519PublicKey(value):
			try value.encode(to: encoder)

		case let .eddsaEd25519Signature(value):
			try value.encode(to: encoder)

		case let .blob(value):
			try value.encode(to: encoder)

		case let .expression(value):
			try value.encode(to: encoder)
		case let .bytes(value):
			try value.encode(to: encoder)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)

		switch kind {
		case .unit:
			self = try .unit(.init(from: decoder))

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
		case .option:
			// `Optional` is already `Codable` so we have to go through its proxy type for JSON coding.
			self = try .option(Value_?.ProxyDecodable(from: decoder).decoded)
		case .result:
			self = try .result(.init(from: decoder))

		case .array:
			self = try .array(.init(from: decoder))

		case .tuple:
			self = try .tuple(.init(from: decoder))

		case .decimal:
			self = try .decimal(.init(from: decoder))

		case .preciseDecimal:
			self = try .preciseDecimal(.init(from: decoder))

		case .component:
			self = try .component(.init(from: decoder))

		case .packageAddress:
			self = try .packageAddress(.init(from: decoder))

		case .componentAddress:
			self = try .componentAddress(.init(from: decoder))

		case .resourceAddress:
			self = try .resourceAddress(.init(from: decoder))

		case .systemAddress:
			self = try .systemAddress(.init(from: decoder))

		case .hash:
			self = try .hash(.init(from: decoder))

		case .bucket:
			self = try .bucket(.init(from: decoder))

		case .proof:
			self = try .proof(.init(from: decoder))

		case .vault:
			self = try .vault(.init(from: decoder))

		case .nonFungibleId:
			self = try .nonFungibleId(.init(from: decoder))

		case .nonFungibleAddress:
			self = try .nonFungibleAddress(.init(from: decoder))

		case .keyValueStore:
			self = try .keyValueStore(.init(from: decoder))

		case .ecdsaSecp256k1PublicKey:
			self = try .ecdsaSecp256k1PublicKey(.init(from: decoder))

		case .ecdsaSecp256k1Signature:
			self = try .ecdsaSecp256k1Signature(.init(from: decoder))

		case .eddsaEd25519PublicKey:
			self = try .eddsaEd25519PublicKey(.init(from: decoder))

		case .eddsaEd25519Signature:
			self = try .eddsaEd25519Signature(.init(from: decoder))

		case .blob:
			self = try .blob(.init(from: decoder))

		case .expression:
			self = try .expression(.init(from: decoder))

		case .bytes:
			self = try .bytes(.init(from: decoder))
		}
	}
}
