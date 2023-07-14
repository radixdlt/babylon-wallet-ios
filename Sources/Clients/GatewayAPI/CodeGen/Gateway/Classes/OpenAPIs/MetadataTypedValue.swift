enum MetadataTypedValue: Codable {
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

        init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                if let type = try? container.decode(String.self, forKey: .type) {
                        switch type {
                        case "String":
                                self = try .stringValue(.init(from: decoder))
                        case "Bool":
                                self = try .boolValue(.init(from: decoder))
                        case "U8":
                                self = try  .u8Value(.init(from: decoder))
                        case "U32":
                                self = try  .u32Value(.init(from: decoder))
                        case "U64":
                                self = try  .u64Value(.init(from: decoder))
                        case "I32":
                                self = try  .i32Value(.init(from: decoder))
                        case "I64":
                                self = try  .i64Value(.init(from: decoder))
                        case "Decimal":
                                self = try  .decimalValue(.init(from: decoder))
                        case "GlobalAddress":
                                self = try  .globalAddressValue(.init(from: decoder))
                        case "PublicKey":
                                self = try  .publicKeyValue(.init(from: decoder))
                        case "NonFungibleGlobalId":
                                self = try  .nonFungibleGlobalIdValue(.init(from: decoder))
                        case "NonFungibleLocalId":
                                self = try  .nonFungibleLocalIdValue(.init(from: decoder))
                        case "Instant":
                                self = try  .instantValue(.init(from: decoder))
                        case "Url":
                                self = try  .urlValue(.init(from: decoder))
                        case "Origin":
                                self = try  .originValue(.init(from: decoder))
                        case "PublicKeyHash":
                                self = try  .publicKeyHashValue(.init(from: decoder))
                        case "StringArray":
                                self = try  .stringArrayValue(.init(from: decoder))
                        case "BoolArray":
                                self = try  .boolArrayValue(.init(from: decoder))
                        case "U8Array":
                                self = try  .u8ArrayValue(.init(from: decoder))
                        case "U32Array":
                                self = try  .u32ArrayValue(.init(from: decoder))
                        case "U64Array":
                                self = try  .u64ArrayValue(.init(from: decoder))
                        case "I32Array":
                                self = try  .i32ArrayValue(.init(from: decoder))
                        case "I64Array":
                                self = try  .i64ArrayValue(.init(from: decoder))
                        case "DecimalArray":
                                self = try  .decimalArrayValue(.init(from: decoder))
                        case "GlobalAddressArray":
                                self = try  .globalAddressArrayValue(.init(from: decoder))
                        case "PublicKeyArray":
                                self = try  .publicKeyArrayValue(.init(from: decoder))
                        case "NonFungibleGlobalIdArray":
                                self = try  .nonFungibleGlobalIdArrayValue(.init(from: decoder))
                        case "NonFungibleLocalIdArray":
                                self = try  .nonFungibleLocalIdArrayValue(.init(from: decoder))
                        case "InstantArray":
                                self = try  .instantArrayValue(.init(from: decoder))
                        case "UrlArray":
                                self = try  .urlArrayValue(.init(from: decoder))
                        case "OriginArray":
                                self = try  .originArrayValue(.init(from: decoder))
                        case "PublicKeyHashArray":
                                self = try  .publicKeyHashArrayValue(.init(from: decoder))
                        default:
                                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type: \(type)")
                        }
                } else {
                        throw DecodingError.keyNotFound(CodingKeys.type, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Type key not found"))
                }
        }

        func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .stringValue(let value):
                        try container.encode("String", forKey: .type)
                        try value.encode(to: encoder)
                case .boolValue(let value):
                        try container.encode("Bool", forKey: .type)
                        try value.encode(to: encoder)
                case .u8Value(let value):
                        try container.encode("U8", forKey: .type)
                        try value.encode(to: encoder)
                case .u32Value(let value):
                        try container.encode("U32", forKey: .type)
                        try value.encode(to: encoder)
                case .u64Value(let value):
                        try container.encode("U64", forKey: .type)
                        try value.encode(to: encoder)
                case .i32Value(let value):
                        try container.encode("I32", forKey: .type)
                        try value.encode(to: encoder)
                case .i64Value(let value):
                        try container.encode("I64", forKey: .type)
                        try value.encode(to: encoder)
                case .decimalValue(let value):
                        try container.encode("Decimal", forKey: .type)
                        try value.encode(to: encoder)
                case .globalAddressValue(let value):
                        try container.encode("GlobalAddress", forKey: .type)
                        try value.encode(to: encoder)
                case .publicKeyValue(let value):
                        try container.encode("PublicKey", forKey: .type)
                        try value.encode(to: encoder)
                case .nonFungibleGlobalIdValue(let value):
                        try container.encode("NonFungibleGlobalId", forKey: .type)
                        try value.encode(to: encoder)
                case .nonFungibleLocalIdValue(let value):
                        try container.encode("NonFungibleLocalId", forKey: .type)
                        try value.encode(to: encoder)
                case .instantValue(let value):
                        try container.encode("Instant", forKey: .type)
                        try value.encode(to: encoder)
                case .urlValue(let value):
                        try container.encode("Url", forKey: .type)
                        try value.encode(to: encoder)
                case .originValue(let value):
                        try container.encode("Origin", forKey: .type)
                        try value.encode(to: encoder)
                case .publicKeyHashValue(let value):
                        try container.encode("PublicKeyHash", forKey: .type)
                        try value.encode(to: encoder)
                case .stringArrayValue(let value):
                        try container.encode("StringArray", forKey: .type)
                        try value.encode(to: encoder)
                case .boolArrayValue(let value):
                        try container.encode("BoolArray", forKey: .type)
                        try value.encode(to: encoder)
                case .u8ArrayValue(let value):
                        try container.encode("U8Array", forKey: .type)
                        try value.encode(to: encoder)
                case .u32ArrayValue(let value):
                        try container.encode("U32Array", forKey: .type)
                        try value.encode(to: encoder)
                case .u64ArrayValue(let value):
                        try container.encode("U64Array", forKey: .type)
                        try value.encode(to: encoder)
                case .i32ArrayValue(let value):
                        try container.encode("I32Array", forKey: .type)
                        try value.encode(to: encoder)
                case .i64ArrayValue(let value):
                        try container.encode("I64Array", forKey: .type)
                        try value.encode(to: encoder)
                case .decimalArrayValue(let value):
                        try container.encode("DecimalArray", forKey: .type)
                        try value.encode(to: encoder)
                case .globalAddressArrayValue(let value):
                        try container.encode("GlobalAddressArray", forKey: .type)
                        try value.encode(to: encoder)
                case .publicKeyArrayValue(let value):
                        try container.encode("PublicKeyArray", forKey: .type)
                        try value.encode(to: encoder)
                case .nonFungibleGlobalIdArrayValue(let value):
                        try container.encode("NonFungibleGlobalIdArray", forKey: .type)
                        try value.encode(to: encoder)
                case .nonFungibleLocalIdArrayValue(let value):
                        try container.encode("NonFungibleLocalIdArray", forKey: .type)
                        try value.encode(to: encoder)
                case .instantArrayValue(let value):
                        try container.encode("InstantArray", forKey: .type)
                        try value.encode(to: encoder)
                case .urlArrayValue(let value):
                        try container.encode("UrlArray", forKey: .type)
                        try value.encode(to: encoder)
                case .originArrayValue(let value):
                        try container.encode("OriginArray", forKey: .type)
                        try value.encode(to: encoder)
                case .publicKeyHashArrayValue(let value):
                        try container.encode("PublicKeyHashArray", forKey: .type)
                        try value.encode(to: encoder)
                }
        }
}
