import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ProgrammaticScryptoSborValue")
typealias ProgrammaticScryptoSborValue = GatewayAPI.ProgrammaticScryptoSborValue

// MARK: - GatewayAPI.ProgrammaticScryptoSborValue
extension GatewayAPI {
	/** Arbitrary SBOR value represented as programmatic JSON with optional property name annotations.  All scalar types (&#x60;Bool&#x60;, &#x60;I*&#x60;, &#x60;U*&#x60;, &#x60;String&#x60;, &#x60;Reference&#x60;, &#x60;Own&#x60;, &#x60;Decimal&#x60;, &#x60;PreciseDecimal&#x60;, &#x60;NonFungibleLocalId&#x60;) convey their value via &#x60;value&#x60; string property with notable exception of &#x60;Bool&#x60; type that uses regular JSON boolean type. Numeric values as string-encoded to preserve accuracy and simplify implementation on platforms with no native support for 64-bit long numerical values.  Common properties represented as nullable strings:   * &#x60;type_name&#x60; is only output when a schema is present and the type has a name,   * &#x60;field_name&#x60; is only output when the value is a child of a &#x60;Tuple&#x60; or &#x60;Enum&#x60;, which has a type with named fields,   * &#x60;variant_name&#x60; is only output when a schema is present and the type is an &#x60;Enum&#x60;.  The following is a non-normative example annotated &#x60;Tuple&#x60; value with &#x60;String&#x60; and &#x60;U32&#x60; fields: &#x60;&#x60;&#x60; {   \&quot;kind\&quot;: \&quot;Tuple\&quot;,   \&quot;type_name\&quot;: \&quot;CustomStructure\&quot;,   \&quot;fields\&quot;: [     {       \&quot;kind\&quot;: \&quot;String\&quot;,       \&quot;field_name\&quot;: \&quot;favorite_color\&quot;,       \&quot;value\&quot;: \&quot;Blue\&quot;     },     {       \&quot;kind\&quot;: \&quot;U32\&quot;,       \&quot;field_name\&quot;: \&quot;usage_counter\&quot;,       \&quot;value\&quot;: \&quot;462231\&quot;     }   ] } &#x60;&#x60;&#x60;  */
	indirect enum ProgrammaticScryptoSborValue: Codable, Hashable {
		case array(ProgrammaticScryptoSborValueArray)
		case bool(ProgrammaticScryptoSborValueBool)
		case bytes(ProgrammaticScryptoSborValueBytes)
		case decimal(ProgrammaticScryptoSborValueDecimal)
		case `enum`(ProgrammaticScryptoSborValueEnum)
		case i8(ProgrammaticScryptoSborValueI8)
		case i16(ProgrammaticScryptoSborValueI16)
		case i32(ProgrammaticScryptoSborValueI32)
		case i64(ProgrammaticScryptoSborValueI64)
		case i128(ProgrammaticScryptoSborValueI128)
		case map(ProgrammaticScryptoSborValueMap)
		case mapEntry(ProgrammaticScryptoSborValueMapEntry)
		case nonFungibleLocalId(ProgrammaticScryptoSborValueNonFungibleLocalId)
		case own(ProgrammaticScryptoSborValueOwn)
		case preciseDecimal(ProgrammaticScryptoSborValuePreciseDecimal)
		case reference(ProgrammaticScryptoSborValueReference)
		case string(ProgrammaticScryptoSborValueString)
		case tuple(ProgrammaticScryptoSborValueTuple)
		case u8(ProgrammaticScryptoSborValueU8)
		case u16(ProgrammaticScryptoSborValueU16)
		case u32(ProgrammaticScryptoSborValueU32)
		case u64(ProgrammaticScryptoSborValueU64)
		case u128(ProgrammaticScryptoSborValueU128)

		var tuple: ProgrammaticScryptoSborValueTuple? {
			if case let .tuple(tuple) = self {
				return tuple
			}
			return nil
		}

		private enum CodingKeys: String, CodingKey {
			case kind
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let kind = try container.decode(ProgrammaticScryptoSborValueKind.self, forKey: .kind)

			switch kind {
			case .bool:
				self = try .bool(.init(from: decoder))
			case .i8:
				self = try .i8(.init(from: decoder))
			case .i16:
				self = try .i16(.init(from: decoder))
			case .i32:
				self = try .i32(.init(from: decoder))
			case .i64:
				self = try .i64(.init(from: decoder))
			case .i128:
				self = try .i128(.init(from: decoder))
			case .u8:
				self = try .u8(.init(from: decoder))
			case .u16:
				self = try .u16(.init(from: decoder))
			case .u32:
				self = try .u32(.init(from: decoder))
			case .u64:
				self = try .u64(.init(from: decoder))
			case .u128:
				self = try .u128(.init(from: decoder))
			case .string:
				self = try .string(.init(from: decoder))
			case ._enum:
				self = try .enum(.init(from: decoder))
			case .array:
				self = try .array(.init(from: decoder))
			case .bytes:
				self = try .bytes(.init(from: decoder))
			case .map:
				self = try .map(.init(from: decoder))
			case .tuple:
				self = try .tuple(.init(from: decoder))
			case .reference:
				self = try .reference(.init(from: decoder))
			case .own:
				self = try .own(.init(from: decoder))
			case .decimal:
				self = try .decimal(.init(from: decoder))
			case .preciseDecimal:
				self = try .preciseDecimal(.init(from: decoder))
			case .nonFungibleLocalId:
				self = try .nonFungibleLocalId(.init(from: decoder))
			}
		}

		func encode(to encoder: Encoder) throws {
			switch self {
			case let .array(value):
				try value.encode(to: encoder)
			case let .bool(value):
				try value.encode(to: encoder)
			case let .bytes(value):
				try value.encode(to: encoder)
			case let .decimal(value):
				try value.encode(to: encoder)
			case let .enum(value):
				try value.encode(to: encoder)
			case let .i8(value):
				try value.encode(to: encoder)
			case let .i16(value):
				try value.encode(to: encoder)
			case let .i32(value):
				try value.encode(to: encoder)
			case let .i64(value):
				try value.encode(to: encoder)
			case let .i128(value):
				try value.encode(to: encoder)
			case let .map(value):
				try value.encode(to: encoder)
			case let .mapEntry(value):
				try value.encode(to: encoder)
			case let .nonFungibleLocalId(value):
				try value.encode(to: encoder)
			case let .own(value):
				try value.encode(to: encoder)
			case let .preciseDecimal(value):
				try value.encode(to: encoder)
			case let .reference(value):
				try value.encode(to: encoder)
			case let .string(value):
				try value.encode(to: encoder)
			case let .tuple(value):
				try value.encode(to: encoder)
			case let .u8(value):
				try value.encode(to: encoder)
			case let .u16(value):
				try value.encode(to: encoder)
			case let .u32(value):
				try value.encode(to: encoder)
			case let .u64(value):
				try value.encode(to: encoder)
			case let .u128(value):
				try value.encode(to: encoder)
			}
		}
	}
}
