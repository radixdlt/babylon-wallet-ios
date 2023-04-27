import Foundation

public enum ManifestASTValueKind: String, Codable, Sendable, Hashable {
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

	case integer = "Integer"

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

	case address = "Address"

	case bucket = "Bucket"
	case proof = "Proof"

	case nonFungibleLocalId = "NonFungibleLocalId"
	case nonFungibleGlobalId = "NonFungibleGlobalId"

	case expression = "Expression"
	case blob = "Blob"
	case bytes = "Bytes"
}
