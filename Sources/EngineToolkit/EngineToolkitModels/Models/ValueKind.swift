import Foundation

public enum ValueKind: String, Codable, Sendable, Hashable {
	case bool = "Bool"

	case u8 = "U8"
	case u16 = "U16"
	case u32 = "U32"
	case u64 = "U64"
	case u128 = "U128"

	case i8 = "I8"
	case i16 = "I16"
	case i32 = "I32"
	case i64 = "I64"
	case i128 = "I128"

	case string = "String"

	case `enum` = "Enum"

	case some = "Some"
	case none = "None"
	case ok = "Ok"
	case err = "Err"

	case map = "Map"
	case array = "Array"
	case tuple = "Tuple"

	case decimal = "Decimal"
	case preciseDecimal = "PreciseDecimal"

	// case own = "Own" // Commented out since the manifest doesn't support this too well right now.

	case componentAddress = "ComponentAddress"
	case resourceAddress = "ResourceAddress"
	case packageAddress = "PackageAddress"

	case ecdsaSecp256k1PublicKey = "EcdsaSecp256k1PublicKey"
	case ecdsaSecp256k1Signature = "EcdsaSecp256k1Signature"
	case eddsaEd25519PublicKey = "EddsaEd25519PublicKey"
	case eddsaEd25519Signature = "EddsaEd25519Signature"

	case bucket = "Bucket"
	case proof = "Proof"

	case nonFungibleLocalId = "NonFungibleLocalId"
	case nonFungibleGlobalId = "NonFungibleGlobalId"

	case expression = "Expression"
	case blob = "Blob"
	case bytes = "Bytes"
}
