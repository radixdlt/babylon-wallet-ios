// MARK: - GatewayAPI.MetadataTypedValue
extension GatewayAPI {
	public enum MetadataTypedValue: Codable, Hashable {
		case stringValue(GatewayAPI.MetadataStringValue)
		case boolValue(GatewayAPI.MetadataBoolValue)
		case u8Value(GatewayAPI.MetadataU8Value)
		case u32Value(GatewayAPI.MetadataU32Value)
		case u64Value(GatewayAPI.MetadataU64Value)
		case i32Value(GatewayAPI.MetadataI32Value)
		case i64Value(GatewayAPI.MetadataI64Value)
		case decimalValue(GatewayAPI.MetadataDecimalValue)
		case globalAddressValue(GatewayAPI.MetadataGlobalAddressValue)
		case publicKeyValue(GatewayAPI.MetadataPublicKeyValue)
		case nonFungibleGlobalIdValue(GatewayAPI.MetadataNonFungibleGlobalIdValue)
		case nonFungibleLocalIdValue(GatewayAPI.MetadataNonFungibleLocalIdValue)
		case instantValue(GatewayAPI.MetadataInstantValue)
		case urlValue(GatewayAPI.MetadataUrlValue)
		case originValue(GatewayAPI.MetadataOriginValue)
		case publicKeyHashValue(GatewayAPI.MetadataPublicKeyHashValue)
		case stringArrayValue(GatewayAPI.MetadataStringArrayValue)
		case boolArrayValue(GatewayAPI.MetadataBoolArrayValue)
		case u8ArrayValue(GatewayAPI.MetadataU8ArrayValue)
		case u32ArrayValue(GatewayAPI.MetadataU32ArrayValue)
		case u64ArrayValue(GatewayAPI.MetadataU64ArrayValue)
		case i32ArrayValue(GatewayAPI.MetadataI32ArrayValue)
		case i64ArrayValue(GatewayAPI.MetadataI64ArrayValue)
		case decimalArrayValue(GatewayAPI.MetadataDecimalArrayValue)
		case globalAddressArrayValue(GatewayAPI.MetadataGlobalAddressArrayValue)
		case publicKeyArrayValue(GatewayAPI.MetadataPublicKeyArrayValue)
		case nonFungibleGlobalIdArrayValue(GatewayAPI.MetadataNonFungibleGlobalIdArrayValue)
		case nonFungibleLocalIdArrayValue(GatewayAPI.MetadataNonFungibleLocalIdArrayValue)
		case instantArrayValue(GatewayAPI.MetadataInstantArrayValue)
		case urlArrayValue(GatewayAPI.MetadataUrlArrayValue)
		case originArrayValue(GatewayAPI.MetadataOriginArrayValue)
		case publicKeyHashArrayValue(GatewayAPI.MetadataPublicKeyHashArrayValue)

		enum CodingKeys: String, CodingKey {
			case type
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			if let type = try? container.decode(String.self, forKey: .type) {
				switch type {
				case "String":
					self = try .stringValue(.init(from: decoder))
				case "Bool":
					self = try .boolValue(.init(from: decoder))
				case "U8":
					self = try .u8Value(.init(from: decoder))
				case "U32":
					self = try .u32Value(.init(from: decoder))
				case "U64":
					self = try .u64Value(.init(from: decoder))
				case "I32":
					self = try .i32Value(.init(from: decoder))
				case "I64":
					self = try .i64Value(.init(from: decoder))
				case "Decimal":
					self = try .decimalValue(.init(from: decoder))
				case "GlobalAddress":
					self = try .globalAddressValue(.init(from: decoder))
				case "PublicKey":
					self = try .publicKeyValue(.init(from: decoder))
				case "NonFungibleGlobalId":
					self = try .nonFungibleGlobalIdValue(.init(from: decoder))
				case "NonFungibleLocalId":
					self = try .nonFungibleLocalIdValue(.init(from: decoder))
				case "Instant":
					self = try .instantValue(.init(from: decoder))
				case "Url":
					self = try .urlValue(.init(from: decoder))
				case "Origin":
					self = try .originValue(.init(from: decoder))
				case "PublicKeyHash":
					self = try .publicKeyHashValue(.init(from: decoder))
				case "StringArray":
					self = try .stringArrayValue(.init(from: decoder))
				case "BoolArray":
					self = try .boolArrayValue(.init(from: decoder))
				case "U8Array":
					self = try .u8ArrayValue(.init(from: decoder))
				case "U32Array":
					self = try .u32ArrayValue(.init(from: decoder))
				case "U64Array":
					self = try .u64ArrayValue(.init(from: decoder))
				case "I32Array":
					self = try .i32ArrayValue(.init(from: decoder))
				case "I64Array":
					self = try .i64ArrayValue(.init(from: decoder))
				case "DecimalArray":
					self = try .decimalArrayValue(.init(from: decoder))
				case "GlobalAddressArray":
					self = try .globalAddressArrayValue(.init(from: decoder))
				case "PublicKeyArray":
					self = try .publicKeyArrayValue(.init(from: decoder))
				case "NonFungibleGlobalIdArray":
					self = try .nonFungibleGlobalIdArrayValue(.init(from: decoder))
				case "NonFungibleLocalIdArray":
					self = try .nonFungibleLocalIdArrayValue(.init(from: decoder))
				case "InstantArray":
					self = try .instantArrayValue(.init(from: decoder))
				case "UrlArray":
					self = try .urlArrayValue(.init(from: decoder))
				case "OriginArray":
					self = try .originArrayValue(.init(from: decoder))
				case "PublicKeyHashArray":
					self = try .publicKeyHashArrayValue(.init(from: decoder))
				default:
					throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type: \(type)")
				}
			} else {
				throw DecodingError.keyNotFound(CodingKeys.type, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Type key not found"))
			}
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			switch self {
			case let .stringValue(value):
				try container.encode("String", forKey: .type)
				try value.encode(to: encoder)
			case let .boolValue(value):
				try container.encode("Bool", forKey: .type)
				try value.encode(to: encoder)
			case let .u8Value(value):
				try container.encode("U8", forKey: .type)
				try value.encode(to: encoder)
			case let .u32Value(value):
				try container.encode("U32", forKey: .type)
				try value.encode(to: encoder)
			case let .u64Value(value):
				try container.encode("U64", forKey: .type)
				try value.encode(to: encoder)
			case let .i32Value(value):
				try container.encode("I32", forKey: .type)
				try value.encode(to: encoder)
			case let .i64Value(value):
				try container.encode("I64", forKey: .type)
				try value.encode(to: encoder)
			case let .decimalValue(value):
				try container.encode("Decimal", forKey: .type)
				try value.encode(to: encoder)
			case let .globalAddressValue(value):
				try container.encode("GlobalAddress", forKey: .type)
				try value.encode(to: encoder)
			case let .publicKeyValue(value):
				try container.encode("PublicKey", forKey: .type)
				try value.encode(to: encoder)
			case let .nonFungibleGlobalIdValue(value):
				try container.encode("NonFungibleGlobalId", forKey: .type)
				try value.encode(to: encoder)
			case let .nonFungibleLocalIdValue(value):
				try container.encode("NonFungibleLocalId", forKey: .type)
				try value.encode(to: encoder)
			case let .instantValue(value):
				try container.encode("Instant", forKey: .type)
				try value.encode(to: encoder)
			case let .urlValue(value):
				try container.encode("Url", forKey: .type)
				try value.encode(to: encoder)
			case let .originValue(value):
				try container.encode("Origin", forKey: .type)
				try value.encode(to: encoder)
			case let .publicKeyHashValue(value):
				try container.encode("PublicKeyHash", forKey: .type)
				try value.encode(to: encoder)
			case let .stringArrayValue(value):
				try container.encode("StringArray", forKey: .type)
				try value.encode(to: encoder)
			case let .boolArrayValue(value):
				try container.encode("BoolArray", forKey: .type)
				try value.encode(to: encoder)
			case let .u8ArrayValue(value):
				try container.encode("U8Array", forKey: .type)
				try value.encode(to: encoder)
			case let .u32ArrayValue(value):
				try container.encode("U32Array", forKey: .type)
				try value.encode(to: encoder)
			case let .u64ArrayValue(value):
				try container.encode("U64Array", forKey: .type)
				try value.encode(to: encoder)
			case let .i32ArrayValue(value):
				try container.encode("I32Array", forKey: .type)
				try value.encode(to: encoder)
			case let .i64ArrayValue(value):
				try container.encode("I64Array", forKey: .type)
				try value.encode(to: encoder)
			case let .decimalArrayValue(value):
				try container.encode("DecimalArray", forKey: .type)
				try value.encode(to: encoder)
			case let .globalAddressArrayValue(value):
				try container.encode("GlobalAddressArray", forKey: .type)
				try value.encode(to: encoder)
			case let .publicKeyArrayValue(value):
				try container.encode("PublicKeyArray", forKey: .type)
				try value.encode(to: encoder)
			case let .nonFungibleGlobalIdArrayValue(value):
				try container.encode("NonFungibleGlobalIdArray", forKey: .type)
				try value.encode(to: encoder)
			case let .nonFungibleLocalIdArrayValue(value):
				try container.encode("NonFungibleLocalIdArray", forKey: .type)
				try value.encode(to: encoder)
			case let .instantArrayValue(value):
				try container.encode("InstantArray", forKey: .type)
				try value.encode(to: encoder)
			case let .urlArrayValue(value):
				try container.encode("UrlArray", forKey: .type)
				try value.encode(to: encoder)
			case let .originArrayValue(value):
				try container.encode("OriginArray", forKey: .type)
				try value.encode(to: encoder)
			case let .publicKeyHashArrayValue(value):
				try container.encode("PublicKeyHashArray", forKey: .type)
				try value.encode(to: encoder)
			}
		}
	}
}

public extension GatewayAPI.MetadataTypedValue {
	var stringValue: GatewayAPI.MetadataStringValue? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	var boolValue: GatewayAPI.MetadataBoolValue? {
		if case let .boolValue(value) = self {
			return value
		}
		return nil
	}

	var u8Value: GatewayAPI.MetadataU8Value? {
		if case let .u8Value(value) = self {
			return value
		}
		return nil
	}

	var u32Value: GatewayAPI.MetadataU32Value? {
		if case let .u32Value(value) = self {
			return value
		}
		return nil
	}

	var u64Value: GatewayAPI.MetadataU64Value? {
		if case let .u64Value(value) = self {
			return value
		}
		return nil
	}

	var i32Value: GatewayAPI.MetadataI32Value? {
		if case let .i32Value(value) = self {
			return value
		}
		return nil
	}

	var i64Value: GatewayAPI.MetadataI64Value? {
		if case let .i64Value(value) = self {
			return value
		}
		return nil
	}

	var decimalValue: GatewayAPI.MetadataDecimalValue? {
		if case let .decimalValue(value) = self {
			return value
		}
		return nil
	}

	var globalAddressValue: GatewayAPI.MetadataGlobalAddressValue? {
		if case let .globalAddressValue(value) = self {
			return value
		}
		return nil
	}

	var publicKeyValue: GatewayAPI.MetadataPublicKeyValue? {
		if case let .publicKeyValue(value) = self {
			return value
		}
		return nil
	}

	var nonFungibleGlobalIdValue: GatewayAPI.MetadataNonFungibleGlobalIdValue? {
		if case let .nonFungibleGlobalIdValue(value) = self {
			return value
		}
		return nil
	}

	var nonFungibleLocalIdValue: GatewayAPI.MetadataNonFungibleLocalIdValue? {
		if case let .nonFungibleLocalIdValue(value) = self {
			return value
		}
		return nil
	}

	var instantValue: GatewayAPI.MetadataInstantValue? {
		if case let .instantValue(value) = self {
			return value
		}
		return nil
	}

	var urlValue: GatewayAPI.MetadataUrlValue? {
		if case let .urlValue(value) = self {
			return value
		}
		return nil
	}

	var originValue: GatewayAPI.MetadataOriginValue? {
		if case let .originValue(value) = self {
			return value
		}
		return nil
	}

	var publicKeyHashValue: GatewayAPI.MetadataPublicKeyHashValue? {
		if case let .publicKeyHashValue(value) = self {
			return value
		}
		return nil
	}

	var stringArrayValue: GatewayAPI.MetadataStringArrayValue? {
		if case let .stringArrayValue(value) = self {
			return value
		}
		return nil
	}

	var boolArrayValue: GatewayAPI.MetadataBoolArrayValue? {
		if case let .boolArrayValue(value) = self {
			return value
		}
		return nil
	}

	var u8ArrayValue: GatewayAPI.MetadataU8ArrayValue? {
		if case let .u8ArrayValue(value) = self {
			return value
		}
		return nil
	}

	var u32ArrayValue: GatewayAPI.MetadataU32ArrayValue? {
		if case let .u32ArrayValue(value) = self {
			return value
		}
		return nil
	}

	var u64ArrayValue: GatewayAPI.MetadataU64ArrayValue? {
		if case let .u64ArrayValue(value) = self {
			return value
		}
		return nil
	}

	var i32ArrayValue: GatewayAPI.MetadataI32ArrayValue? {
		if case let .i32ArrayValue(value) = self {
			return value
		}
		return nil
	}

	var i64ArrayValue: GatewayAPI.MetadataI64ArrayValue? {
		if case let .i64ArrayValue(value) = self {
			return value
		}
		return nil
	}

	var decimalArrayValue: GatewayAPI.MetadataDecimalArrayValue? {
		if case let .decimalArrayValue(value) = self {
			return value
		}
		return nil
	}

	var globalAddressArrayValue: GatewayAPI.MetadataGlobalAddressArrayValue? {
		if case let .globalAddressArrayValue(value) = self {
			return value
		}
		return nil
	}

	var publicKeyArrayValue: GatewayAPI.MetadataPublicKeyArrayValue? {
		if case let .publicKeyArrayValue(value) = self {
			return value
		}
		return nil
	}

	var nonFungibleGlobalIdArrayValue: GatewayAPI.MetadataNonFungibleGlobalIdArrayValue? {
		if case let .nonFungibleGlobalIdArrayValue(value) = self {
			return value
		}
		return nil
	}

	var nonFungibleLocalIdArrayValue: GatewayAPI.MetadataNonFungibleLocalIdArrayValue? {
		if case let .nonFungibleLocalIdArrayValue(value) = self {
			return value
		}
		return nil
	}

	var instantArrayValue: GatewayAPI.MetadataInstantArrayValue? {
		if case let .instantArrayValue(value) = self {
			return value
		}
		return nil
	}

	var urlArrayValue: GatewayAPI.MetadataUrlArrayValue? {
		if case let .urlArrayValue(value) = self {
			return value
		}
		return nil
	}

	var originArrayValue: GatewayAPI.MetadataOriginArrayValue? {
		if case let .originArrayValue(value) = self {
			return value
		}
		return nil
	}

	var publicKeyHashArrayValue: GatewayAPI.MetadataPublicKeyHashArrayValue? {
		if case let .publicKeyHashArrayValue(value) = self {
			return value
		}
		return nil
	}
}
