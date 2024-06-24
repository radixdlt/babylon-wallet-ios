import Foundation

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
