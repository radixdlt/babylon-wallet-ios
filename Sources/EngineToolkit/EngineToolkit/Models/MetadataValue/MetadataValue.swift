import CasePaths
import Foundation

// MARK: - MetadataValue
public indirect enum MetadataValue: Sendable, Codable, Hashable {
	// ==============
	// Enum Variants
	// ==============

	case boolean(Bool)

	case i32(Int32)
	case i64(Int64)

	case u8(UInt8)
	case u32(UInt32)
	case u64(UInt64)
	case string(String)

	case decimal(Decimal_)

	case url(URL)
	case origin(Origin)
	case instant(Instant)

	case globalAddress(Address)
	case nonFungibleGlobalId(NonFungibleGlobalId)
	case nonFungibleLocalId(NonFungibleLocalId)
	case publicKey(Engine.PublicKey)
	case publicKeyHash(PublicKeyHash)

	case boolArray([Bool])

	case i32Array([Int32])
	case i64Array([Int64])

	case u8Array([UInt8])
	case u32Array([UInt32])
	case u64Array([UInt64])
	case stringArray([String])

	case decimalArray([Decimal_])

	case urlArray([URL])
	case originArray([Origin])
	case instantArray([Instant])

	case globalAddressArray([Address])
	case nonFungibleGlobalIdArray([NonFungibleGlobalId])
	case nonFungibleLocalIdArray([NonFungibleLocalId])
	case publicKeyArray([Engine.PublicKey])
	case publicKeyHashArray([PublicKeyHash])

	public var string: String? {
		guard case let .string(string) = self else {
			return nil
		}
		return string
	}
}

// MARK: - MetadataValueKind
public indirect enum MetadataValueKind: String, Sendable, Codable, Hashable, CaseIterable {
	// ==============
	// Enum Variants
	// ==============

	case boolean = "Bool"

	case i32 = "I32"
	case i64 = "I64"

	case u8 = "U8"
	case u32 = "U32"
	case u64 = "U64"
	case string = "String"

	case decimal = "Decimal"

	case url = "Url"
	case origin = "Origin"
	case instant = "Instant"

	case globalAddress = "GlobalAddress"
	case nonFungibleGlobalId = "NonFungibleGlobalId"
	case nonFungibleLocalId = "NonFungibleLocalId"
	case publicKey = "PublicKey"
	case publicKeyHash = "PublicKeyHash"

	case boolArray = "BoolArray"

	case i32Array = "I32Array"
	case i64Array = "I64Array"

	case u8Array = "U8Array"
	case u32Array = "U32Array"
	case u64Array = "U64Array"
	case stringArray = "StringArray"

	case decimalArray = "DecimalArray"

	case urlArray = "UrlArray"
	case originArray = "OriginArray"
	case instantArray = "InstantArray"

	case globalAddressArray = "GlobalAddressArray"
	case nonFungibleGlobalIdArray = "NonFungibleGlobalIdArray"
	case nonFungibleLocalIdArray = "NonFungibleLocalIdArray"
	case publicKeyArray = "PublicKeyArray"
	case publicKeyHashArray = "PublicKeyHashArray"
}

extension MetadataValue {
	var kind: MetadataValueKind {
		switch self {
		case .boolean:
			return .boolean
		case .i32:
			return .i32
		case .i64:
			return .i64
		case .u8:
			return .u8
		case .u32:
			return .u32
		case .u64:
			return .u64
		case .string:
			return .string
		case .decimal:
			return .decimal
		case .url:
			return .url
		case .origin:
			return .origin
		case .globalAddress:
			return .globalAddress
		case .nonFungibleGlobalId:
			return .nonFungibleGlobalId
		case .nonFungibleLocalId:
			return .nonFungibleLocalId
		case .instant:
			return .instant
		case .publicKey:
			return .publicKey
		case .publicKeyHash:
			return .publicKeyHash
		case .boolArray:
			return .boolArray
		case .i32Array:
			return .i32Array
		case .i64Array:
			return .i64Array
		case .u8Array:
			return .u8Array
		case .u32Array:
			return .u32Array
		case .u64Array:
			return .u64Array
		case .stringArray:
			return .stringArray
		case .decimalArray:
			return .decimalArray
		case .urlArray:
			return .urlArray
		case .originArray:
			return .originArray
		case .instantArray:
			return .instantArray
		case .globalAddressArray:
			return .globalAddressArray
		case .nonFungibleGlobalIdArray:
			return .nonFungibleGlobalIdArray
		case .nonFungibleLocalIdArray:
			return .nonFungibleLocalIdArray
		case .publicKeyArray:
			return .publicKeyArray
		case .publicKeyHashArray:
			return .publicKeyHashArray
		}
	}
}

extension MetadataValue {
	private enum CodingKeys: String, CodingKey {
		case type
		case value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(MetadataValueKind.self, forKey: .type)

		switch kind {
		case .boolean:
			self = try .boolean(container.decode(forKey: .value))
		case .i32:
			self = try .i32(IntegerCodable(from: decoder).value)
		case .i64:
			self = try .i64(IntegerCodable(from: decoder).value)
		case .u8:
			self = try .u8(IntegerCodable(from: decoder).value)
		case .u32:
			self = try .u32(IntegerCodable(from: decoder).value)
		case .u64:
			self = try .u64(IntegerCodable(from: decoder).value)
		case .string:
			self = try .string(container.decode(forKey: .value))
		case .decimal:
			self = try .decimal(container.decode(forKey: .value))
		case .url:
			self = try .url(container.decode(forKey: .value))
		case .origin:
			self = try .origin(container.decode(forKey: .value))
		case .instant:
			self = try .instant(container.decode(forKey: .value))
		case .globalAddress:
			self = try .globalAddress(container.decode(forKey: .value))
		case .nonFungibleGlobalId:
			self = try .nonFungibleGlobalId(container.decode(forKey: .value))
		case .nonFungibleLocalId:
			self = try .nonFungibleLocalId(container.decode(forKey: .value))
		case .publicKey:
			self = try .publicKey(container.decode(forKey: .value))
		case .publicKeyHash:
			self = try .publicKeyHash(container.decode(forKey: .value))
		case .boolArray:
			self = try .boolArray(container.decode(forKey: .value))
		case .i32Array:
			self = try .i32Array(container.decode([IntFromStringCodable].self, forKey: .value).map(\.value))
		case .i64Array:
			self = try .i64Array(container.decode([IntFromStringCodable].self, forKey: .value).map(\.value))
		case .u8Array:
			self = try .u8Array(container.decode([IntFromStringCodable].self, forKey: .value).map(\.value))
		case .u32Array:
			self = try .u32Array(container.decode([IntFromStringCodable].self, forKey: .value).map(\.value))
		case .u64Array:
			self = try .u64Array(container.decode([IntFromStringCodable].self, forKey: .value).map(\.value))
		case .stringArray:
			self = try .stringArray(container.decode(forKey: .value))
		case .decimalArray:
			self = try .decimalArray(container.decode(forKey: .value))
		case .urlArray:
			self = try .urlArray(container.decode(forKey: .value))
		case .originArray:
			self = try .originArray(container.decode(forKey: .value))
		case .instantArray:
			self = try .instantArray(container.decode(forKey: .value))
		case .globalAddressArray:
			self = try .globalAddressArray(container.decode(forKey: .value))
		case .nonFungibleGlobalIdArray:
			self = try .nonFungibleGlobalIdArray(container.decode(forKey: .value))
		case .nonFungibleLocalIdArray:
			self = try .nonFungibleLocalIdArray(container.decode(forKey: .value))
		case .publicKeyArray:
			self = try .publicKeyArray(container.decode(forKey: .value))
		case .publicKeyHashArray:
			self = try .publicKeyHashArray(container.decode(forKey: .value))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(kind, forKey: .type)

		switch self {
		case let .boolean(value):
			try container.encode(value, forKey: .value)
		case let .i32(value):
			try IntegerCodable(value).encode(to: encoder)
		case let .i64(value):
			try IntegerCodable(value).encode(to: encoder)
		case let .u8(value):
			try IntegerCodable(value).encode(to: encoder)
		case let .u32(value):
			try IntegerCodable(value).encode(to: encoder)
		case let .u64(value):
			try IntegerCodable(value).encode(to: encoder)
		case let .string(value):
			try container.encode(value, forKey: .value)
		case let .decimal(value):
			try container.encode(value, forKey: .value)
		case let .url(value):
			try container.encode(value, forKey: .value)
		case let .origin(value):
			try container.encode(value, forKey: .value)
		case let .instant(value):
			try container.encode(value, forKey: .value)
		case let .globalAddress(value):
			try container.encode(value, forKey: .value)
		case let .nonFungibleGlobalId(value):
			try container.encode(value, forKey: .value)
		case let .nonFungibleLocalId(value):
			try container.encode(value, forKey: .value)
		case let .publicKey(value):
			try container.encode(value, forKey: .value)
		case let .publicKeyHash(value):
			try container.encode(value, forKey: .value)
		case let .boolArray(value):
			try container.encode(value, forKey: .value)
		case let .i32Array(value):
			try container.encode(value.map(IntFromStringCodable.init), forKey: .value)
		case let .i64Array(value):
			try container.encode(value.map(IntFromStringCodable.init), forKey: .value)
		case let .u8Array(value):
			try container.encode(value.map(IntFromStringCodable.init), forKey: .value)
		case let .u32Array(value):
			try container.encode(value.map(IntFromStringCodable.init), forKey: .value)
		case let .u64Array(value):
			try container.encode(value.map(IntFromStringCodable.init), forKey: .value)
		case let .stringArray(value):
			try container.encode(value, forKey: .value)
		case let .decimalArray(value):
			try container.encode(value, forKey: .value)
		case let .urlArray(value):
			try container.encode(value, forKey: .value)
		case let .originArray(value):
			try container.encode(value, forKey: .value)
		case let .instantArray(value):
			try container.encode(value, forKey: .value)
		case let .globalAddressArray(value):
			try container.encode(value, forKey: .value)
		case let .nonFungibleGlobalIdArray(value):
			try container.encode(value, forKey: .value)
		case let .nonFungibleLocalIdArray(value):
			try container.encode(value, forKey: .value)
		case let .publicKeyArray(value):
			try container.encode(value, forKey: .value)
		case let .publicKeyHashArray(value):
			try container.encode(value, forKey: .value)
		}
	}
}

extension KeyedDecodingContainer {
	func decode<V: Decodable>(forKey key: KeyedDecodingContainer<K>.Key) throws -> V {
		try decode(V.self, forKey: key)
	}
}

// MARK: - MetadataValue.NonFungibleGlobalId
extension MetadataValue {
	public struct NonFungibleGlobalId: Sendable, Codable, Hashable {
		let value: String

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			self.value = try container.decode(String.self)
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(self.value)
		}
	}
}

// MARK: - Instant
public struct Instant: Sendable, Codable, Hashable {
	let value: String

	init(value: String) {
		self.value = value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.value = try container.decode(String.self)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.value)
	}
}

// MARK: - Origin
public struct Origin: Sendable, Codable, Hashable {
	let value: String

	init(value: String) {
		self.value = value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.value = try container.decode(String.self)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.value)
	}
}

// MARK: - PublicKeyHash
public enum PublicKeyHash: Sendable, Codable, Hashable {
	case ecdsaSecp256k1(String)
	case eddsaEd25519(String)

	private enum CodingKeys: String, CodingKey {
		case discriminator = "curve"
		case publicKeyHash = "public_key_hash"
	}

	internal var discriminator: CurveDiscriminator {
		switch self {
		case .ecdsaSecp256k1: return .ecdsaSecp256k1
		case .eddsaEd25519: return .eddsaEd25519
		}
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .ecdsaSecp256k1(publicKey):
			try container.encode(discriminator, forKey: .discriminator)
			try container.encode(publicKey, forKey: .publicKeyHash)
		case let .eddsaEd25519(publicKey):
			try container.encode(discriminator, forKey: .discriminator)
			try container.encode(publicKey, forKey: .publicKeyHash)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(CurveDiscriminator.self, forKey: .discriminator)

		switch discriminator {
		case .ecdsaSecp256k1:
			self = try .ecdsaSecp256k1(container.decode(forKey: .publicKeyHash))
		case .eddsaEd25519:
			self = try .eddsaEd25519(container.decode(forKey: .publicKeyHash))
		}
	}
}

/*
 Instant {
     #[schemars(with = "String")]
     #[serde_as(as = "serde_with::DisplayFromStr")]
     value: i64,
 },

 Url {
     value: String,
 },

 Origin {
     value: String,
 },

 PublicKeyHash {
     #[schemars(with = "crate::model::crypto::PublicKeyHash")]
     #[serde_as(as = "serde_with::FromInto<crate::model::crypto::PublicKeyHash>")]
     value: PublicKeyHash,
 },

 StringArray {
     value: Vec<String>,
 },

 BoolArray {
     value: Vec<bool>,
 },

 U8Array {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<u8>,
 },

 U32Array {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<u32>,
 },

 U64Array {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<u64>,
 },

 I32Array {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<i32>,
 },

 I64Array {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<i64>,
 },

 DecimalArray {
     #[schemars(regex(pattern = "[0-9]+"))]
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<Decimal>,
 },

 GlobalAddressArray {
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<NetworkAwareNodeId>,
 },

 PublicKeyArray {
     #[schemars(with = "Vec<crate::model::crypto::PublicKey>")]
     #[serde_as(as = "Vec<serde_with::FromInto<crate::model::crypto::PublicKey>>")]
     value: Vec<PublicKey>,
 },

 NonFungibleGlobalIdArray {
     value: Vec<String>,
 },

 NonFungibleLocalIdArray {
     value: Vec<String>,
 },

 InstantArray {
     #[schemars(with = "Vec<String>")]
     #[serde_as(as = "Vec<serde_with::DisplayFromStr>")]
     value: Vec<i64>,
 },

 UrlArray {
     value: Vec<String>,
 },

 OriginArray {
     value: Vec<String>,
 },

 PublicKeyHashArray {
     #[schemars(with = "Vec<crate::model::crypto::PublicKeyHash>")]
     #[serde_as(as = "Vec<serde_with::FromInto<crate::model::crypto::PublicKeyHash>>")]
     value: Vec<PublicKeyHash>,
 },

 */
