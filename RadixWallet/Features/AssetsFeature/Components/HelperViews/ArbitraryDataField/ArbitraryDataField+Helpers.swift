import Foundation

extension [GatewayAPI.EntityMetadataItem] {
	var asDataFields: [ArbitraryDataField] {
		compactMap { item in
			let kind: ArbitraryDataField.Kind? = switch item.value.typed {
			case let .boolValue(content):
				.primitive(String(content.value))
			case let .stringValue(content):
				content.value.asDataField
			case let .u8Value(content):
				content.value.asPrimitiveDataField
			case let .u32Value(content):
				content.value.asPrimitiveDataField
			case let .u64Value(content):
				content.value.asPrimitiveDataField
			case let .i32Value(content):
				content.value.asPrimitiveDataField
			case let .i64Value(content):
				content.value.asPrimitiveDataField
			case let .decimalValue(content):
				content.value.asDecimalDataField
			case let .globalAddressValue(content):
				content.value.asLedgerAddressDataField
			case let .publicKeyValue(content):
				switch content.value {
				case let .ecdsaSecp256k1(key):
					.primitive(key.keyHex)
				case let .eddsaEd25519(key):
					.primitive(key.keyHex)
				}
			case let .nonFungibleLocalIdValue(content):
				.primitive(content.value)
			case let .instantValue(content):
				if let date = OpenISO8601DateFormatter.withoutSeconds.date(from: content.value) {
					.instant(date)
				} else {
					.primitive(content.value)
				}
			case let .urlValue(content):
				content.value.asDataField
			case let .originValue(content):
				content.value.asDataField
			case let .publicKeyHashValue(content):
				switch content.value {
				case let .ecdsaSecp256k1(hash):
					.primitive(hash.hashHex)
				case let .eddsaEd25519(hash):
					.primitive(hash.hashHex)
				}
			case .u8ArrayValue, .i32ArrayValue, .i64ArrayValue, .u32ArrayValue, .u64ArrayValue, .urlArrayValue, .boolArrayValue, .originArrayValue,
			     .stringArrayValue, .decimalArrayValue, .instantArrayValue, .publicKeyArrayValue, .globalAddressArrayValue, .publicKeyHashArrayValue,
			     .nonFungibleLocalIdArrayValue, .nonFungibleGlobalIdArrayValue, .nonFungibleGlobalIdValue:
				.complex
			}
			guard let kind else {
				return nil
			}
			return .init(kind: kind, name: item.key)
		}
	}
}

extension GatewayAPI.ProgrammaticScryptoSborValue {
	enum TypeName: String {
		case instant = "Instant"
	}

	var fieldKind: ArbitraryDataField.Kind? {
		switch self {
		case .array, .map, .mapEntry, .tuple:
			.complex
		case let .bool(content):
			.primitive(String(content.value))
		case let .bytes(content):
			content.hex.asPrimitiveDataField
		case let .i8(content):
			content.value.asPrimitiveDataField
		case let .i16(content):
			content.value.asPrimitiveDataField
		case let .i32(content):
			content.value.asPrimitiveDataField
		case let .i64(content):
			if content.typeName == TypeName.instant.rawValue {
				content.value.asInstantDataField
			} else {
				content.value.asPrimitiveDataField
			}
		case let .i128(content):
			content.value.asPrimitiveDataField
		case let .u8(content):
			content.value.asPrimitiveDataField
		case let .u16(content):
			content.value.asPrimitiveDataField
		case let .u32(content):
			content.value.asPrimitiveDataField
		case let .u64(content):
			content.value.asPrimitiveDataField
		case let .u128(content):
			content.value.asPrimitiveDataField
		case let .decimal(content):
			content.value.asDecimalDataField
		case let .preciseDecimal(content):
			content.value.asDecimalDataField
		case let .enum(content):
			content.variantName.map { .enum(variant: $0) }
		case let .nonFungibleLocalId(content):
			content.value.asNonFungibleIDDataField
		case let .own(content):
			content.value.asLedgerAddressDataField
		case let .reference(content):
			content.value.asLedgerAddressDataField
		case let .string(content):
			content.value.asDataField
		}
	}
}

extension GatewayAPI.ProgrammaticScryptoSborValue {
	var fieldName: String? {
		let name = switch self {
		case let .array(content):
			content.fieldName
		case let .bool(content):
			content.fieldName
		case let .bytes(content):
			content.fieldName
		case let .decimal(content):
			content.fieldName
		case let .enum(content):
			content.fieldName
		case let .i8(content):
			content.fieldName
		case let .i16(content):
			content.fieldName
		case let .i32(content):
			content.fieldName
		case let .i64(content):
			content.fieldName
		case let .i128(content):
			content.fieldName
		case let .map(content):
			content.fieldName
		case let .mapEntry(entry):
			entry.key.fieldName
		case let .nonFungibleLocalId(content):
			content.fieldName
		case let .own(content):
			content.fieldName
		case let .preciseDecimal(content):
			content.fieldName
		case let .reference(content):
			content.fieldName
		case let .string(content):
			content.fieldName
		case let .tuple(content):
			content.fieldName
		case let .u8(content):
			content.fieldName
		case let .u16(content):
			content.fieldName
		case let .u32(content):
			content.fieldName
		case let .u64(content):
			content.fieldName
		case let .u128(content):
			content.fieldName
		}

		return name?.nilIfEmpty
	}
}

private typealias ArbitraryDataFieldKind = ArbitraryDataField.Kind

private extension String {
	var asDataField: ArbitraryDataField.Kind? {
		nilIfEmpty.map {
			if let url = URL(string: $0), ["http", "https"].contains(url.scheme) {
				.url(url)
			} else {
				.primitive(self)
			}
		}
	}

	var asPrimitiveDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map { .primitive($0) }
	}

	var asLedgerAddressDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let address = try? LedgerIdentifiable.Address(address: Address(validatingAddress: $0)) {
				.address(address)
			} else {
				.primitive(self)
			}
		}
	}

	var asDecimalDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let decimal = try? Decimal192($0) {
				.decimal(decimal)
			} else {
				.primitive(self)
			}
		}
	}

	var asNonFungibleIDDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let id = try? NonFungibleLocalID($0) {
				.id(id)
			} else {
				.primitive(self)
			}
		}
	}

	var asInstantDataField: ArbitraryDataFieldKind? {
		nilIfEmpty.map {
			if let timeInterval = Int64($0) {
				.instant(Date(timeIntervalSince1970: TimeInterval(timeInterval)))
			} else {
				.primitive(self)
			}
		}
	}
}
