import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class ValueEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		// Arrange
		let testVectors: [(value: ManifestASTValue, jsonRepresentation: String)] = [
			(
				value: .boolean(false),
				jsonRepresentation: """
				{"type":"Bool","value":false}
				"""
			),
			(
				value: .boolean(true),
				jsonRepresentation: """
				{"type":"Bool","value":true}
				"""
			),
			(
				value: .u8(1),
				jsonRepresentation: """
				{"type":"U8","value":"1"}
				"""
			),
			(
				value: .u16(1),
				jsonRepresentation: """
				{"type":"U16","value":"1"}
				"""
			),
			(
				value: .u32(1),
				jsonRepresentation: """
				{"type":"U32","value":"1"}
				"""
			),
			(
				value: .u64(1),
				jsonRepresentation: """
				{"type":"U64","value":"1"}
				"""
			),
			(
				value: .u128("1"),
				jsonRepresentation: """
				{"type":"U128","value":"1"}
				"""
			),
			(
				value: .i8(1),
				jsonRepresentation: """
				{"type":"I8","value":"1"}
				"""
			),
			(
				value: .i16(1),
				jsonRepresentation: """
				{"type":"I16","value":"1"}
				"""
			),
			(
				value: .i32(1),
				jsonRepresentation: """
				{"type":"I32","value":"1"}
				"""
			),
			(
				value: .i64(1),
				jsonRepresentation: """
				{"type":"I64","value":"1"}
				"""
			),
			(
				value: .i128("1"),
				jsonRepresentation: """
				{"type":"I128","value":"1"}
				"""
			),
			(
				value: .string("Scrypto"),
				jsonRepresentation: """
				{"type":"String","value":"Scrypto"}
				"""
			),
			(
				value: .enum(.init(.u8(1))),
				jsonRepresentation: """
				{"type":"Enum","variant":{"type":"U8","discriminator":"1"}}
				"""
			),
			(
				value: .enum(.init(.string("EnumName::Variant"))),
				jsonRepresentation: """
				{"type":"Enum","variant":{"type":"String","discriminator":"EnumName::Variant"}}
				"""
			),
			(
				value: .enum(.init(.string("EnumName::Variant"), fields: [.u8(1)])),
				jsonRepresentation: """
				{"type":"Enum","variant":{"type":"String","discriminator":"EnumName::Variant"},"fields":[{"type":"U8","value":"1"}]}
				"""
			),
			(
				value: .some(.init(.u8(1))),
				jsonRepresentation: """
				{"type":"Some","value":{"type":"U8","value":"1"}}
				"""
			),
			(
				value: .none,
				jsonRepresentation: """
				{"type":"None"}
				"""
			),
			(
				value: .ok(.init(.u8(1))),
				jsonRepresentation: """
				{"type":"Ok","value":{"type":"U8","value":"1"}}
				"""
			),
			(
				value: .err(.init(.u8(1))),
				jsonRepresentation: """
				{"type":"Err","value":{"type":"U8","value":"1"}}
				"""
			),
			try (
				value: .array(.init(elementKind: .u8, elements: [.u8(1), .u8(2), .u8(3)])),
				jsonRepresentation: """
				{"type":"Array","element_kind":"U8","elements":[{"type":"U8","value":"1"},{"type":"U8","value":"2"},{"type":"U8","value":"3"}]}
				"""
			),
			(
				value: .map(.init(keyValueKind: .u8,
				                  valueValueKind: .string,
				                  entries: [
				                  	[.u8(65), .string("A")],
				                  	[.u8(66), .string("B")],
				                  ])),
				jsonRepresentation: """
				{"entries":[[{"type":"U8","value":"65"},{"type":"String","value":"A"}],[{"type":"U8","value":"66"},{"type":"String","value":"B"}]],"type":"Map","key_value_kind":"U8","value_value_kind":"String"}
				"""
			),
			(
				value: .tuple(.init(values: [
					.tuple(.init(values: [.u8(1), .string("Something")])),
				])),
				jsonRepresentation: """
				{"type":"Tuple","elements":[{"type":"Tuple","elements":[{"type":"U8","value":"1"},{"type":"String","value":"Something"}]}]}
				"""
			),
			(
				value: .decimal(.init(value: "1")),
				jsonRepresentation: """
				{"type":"Decimal","value":"1"}
				"""
			),
			(
				value: .preciseDecimal(.init(value: "1")),
				jsonRepresentation: """
				{"type":"PreciseDecimal","value":"1"}
				"""
			),
			(
				value: .address("component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
				jsonRepresentation: """
				{"type":"Address","address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"}
				"""
			),
			(
				value: .address("resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
				jsonRepresentation: """
				{"type":"Address","address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"}
				"""
			),
			(
				value: .address("package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8"),
				jsonRepresentation: """
				{"type":"Address","address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8"}
				"""
			),
			(
				value: .bucket(.init(identifier: .string("bucket"))),
				jsonRepresentation: """
				{"type":"Bucket","identifier":{"type":"String","value":"bucket"}}
				"""
			),
			(
				value: .bucket(.init(identifier: .u32(1))),
				jsonRepresentation: """
				{"type":"Bucket","identifier":{"type":"U32","value":"1"}}
				"""
			),
			(
				value: .proof(.init(identifier: .string("proof"))),
				jsonRepresentation: """
				{"type":"Proof","identifier":{"type":"String","value":"proof"}}
				"""
			),
			(
				value: .proof(.init(identifier: .u32(1))),
				jsonRepresentation: """
				{"type":"Proof","identifier":{"type":"U32","value":"1"}}
				"""
			),
			(
				value: .nonFungibleLocalId(.uuid("241008287272164729465721528295504357972")),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"UUID","value":"241008287272164729465721528295504357972"}}
				"""
			),
			(
				value: .nonFungibleLocalId(.integer(1)),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}
				"""
			),
			(
				value: .nonFungibleLocalId(.string("Scrypto")),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"String","value":"Scrypto"}}
				"""
			),
			(
				value: .nonFungibleLocalId(.bytes([0x01, 0x02, 0x03, 0x04])),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"Bytes","value":"01020304"}}
				"""
			),
			(
				value: .nonFungibleGlobalId(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g",
					nonFungibleLocalId: .uuid("241008287272164729465721528295504357972")
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"Address","address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"UUID","value":"241008287272164729465721528295504357972"}}}
				"""
			),
			(
				value: .nonFungibleGlobalId(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g",
					nonFungibleLocalId: .integer(1)
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"Address","address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}}
				"""
			),
			(
				value: .nonFungibleGlobalId(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g",
					nonFungibleLocalId: .string("Scrypto")
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"Address","address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"String","value":"Scrypto"}}}
				"""
			),
			(
				value: .nonFungibleGlobalId(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g",
					nonFungibleLocalId: .bytes([0x01, 0x02, 0x03, 0x04])
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"Address","address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Bytes","value":"01020304"}}}
				"""
			),
			(
				value: .expression(.init(value: "ENTIRE_AUTH_ZONE")),
				jsonRepresentation: """
				{"type":"Expression","value":"ENTIRE_AUTH_ZONE"}
				"""
			),
			(
				value: .expression(.init(value: "ENTIRE_WORKTOP")),
				jsonRepresentation: """
				{"type":"Expression","value":"ENTIRE_WORKTOP"}
				"""
			),
			try (
				value: .blob(.init(hex: "d28d2c3710601fbc097000ec73455693f4861dc0eb7c90d8821f2a13f617313e")),
				jsonRepresentation: """
				{"type":"Blob","hash":"d28d2c3710601fbc097000ec73455693f4861dc0eb7c90d8821f2a13f617313e"}
				"""
			),
			try (
				value: .bytes(.init(hex: "d28d2c3710601fbc097000ec73455693f4861dc0eb7c90d8821f2a13f617313e")),
				jsonRepresentation: """
				{"type":"Bytes","value":"d28d2c3710601fbc097000ec73455693f4861dc0eb7c90d8821f2a13f617313e"}
				"""
			),
		]

		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		encoder.outputFormatting = [.withoutEscapingSlashes]

		for (value, jsonRepresentation) in testVectors {
			// Act
			let string = try XCTUnwrap(String(data: encoder.encode(value), encoding: .utf8))

			// Assert
			XCTAssertNoDifference(string, jsonRepresentation)

			// Act
			let decodedValue = try decoder.decode(ManifestASTValue.self, from: jsonRepresentation.data(using: .utf8)!)

			// Assert
			XCTAssertEqual(value, decodedValue)
		}
	}
}
