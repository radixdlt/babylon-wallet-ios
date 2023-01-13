import Foundation

public enum ValueKind: String, Codable, Sendable, Hashable {
	case unit = "Unit"
	case bool = "Bool"

	case i8 = "I8"
	case i16 = "I16"
	case i32 = "I32"
	case i64 = "I64"
	case i128 = "I128"

	case u8 = "U8"
	case u16 = "U16"
	case u32 = "U32"
	case u64 = "U64"
	case u128 = "U128"

	case string = "String"

	case `enum` = "Enum"

	case option = "Option"
	case result = "Result"
	case array = "Array"
	case tuple = "Tuple"

	case decimal = "Decimal"
	case preciseDecimal = "PreciseDecimal"

	case component = "Component"
	case packageAddress = "PackageAddress"
	case componentAddress = "ComponentAddress"
	case resourceAddress = "ResourceAddress"
	case systemAddress = "SystemAddress"

	case hash = "Hash"

	case bucket = "Bucket"
	case proof = "Proof"
	case vault = "Vault"

	case nonFungibleId = "NonFungibleId"
	case nonFungibleAddress = "NonFungibleAddress"

	case keyValueStore = "KeyValueStore"

	case ecdsaSecp256k1PublicKey = "EcdsaSecp256k1PublicKey"
	case ecdsaSecp256k1Signature = "EcdsaSecp256k1Signature"
	case eddsaEd25519PublicKey = "EddsaEd25519PublicKey"
	case eddsaEd25519Signature = "EddsaEd25519Signature"

	case blob = "Blob"
	case expression = "Expression"
	case bytes = "Bytes"
}
