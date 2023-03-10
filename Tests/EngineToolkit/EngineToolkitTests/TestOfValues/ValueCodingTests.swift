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
		let testVectors: [(value: Value_, jsonRepresentation: String)] = [
			(
				value: Value_.boolean(true),
				jsonRepresentation: """
				{"type":"Bool","value":true}
				"""
			),

			(
				value: Value_.u8(1),
				jsonRepresentation: """
				{"type":"U8","value":"1"}
				"""
			),
			(
				value: Value_.u16(1),
				jsonRepresentation: """
				{"type":"U16","value":"1"}
				"""
			),
			(
				value: Value_.u32(1),
				jsonRepresentation: """
				{"type":"U32","value":"1"}
				"""
			),
			(
				value: Value_.u64(1),
				jsonRepresentation: """
				{"type":"U64","value":"1"}
				"""
			),
			(
				value: Value_.u128("1"),
				jsonRepresentation: """
				{"type":"U128","value":"1"}
				"""
			),

			(
				value: Value_.i8(1),
				jsonRepresentation: """
				{"type":"I8","value":"1"}
				"""
			),
			(
				value: Value_.i16(1),
				jsonRepresentation: """
				{"type":"I16","value":"1"}
				"""
			),
			(
				value: Value_.i32(1),
				jsonRepresentation: """
				{"type":"I32","value":"1"}
				"""
			),
			(
				value: Value_.i64(1),
				jsonRepresentation: """
				{"type":"I64","value":"1"}
				"""
			),
			(
				value: Value_.i128("1"),
				jsonRepresentation: """
				{"type":"I128","value":"1"}
				"""
			),

			(
				value: Value_.string("P2P Cash System"),
				jsonRepresentation: """
				{"type":"String","value":"P2P Cash System"}
				"""
			),
			(
				value: Value_.enum(.init(.string("HelloWold"), fields: [.u8(1)])),
				jsonRepresentation: """
				{"type":"Enum","variant":{"type":"String","discriminator":"HelloWold"},"fields":[{"type":"U8","value":"1"}]}
				"""
			),

			(
				value: Value_.enum(.init(.u8(1), fields: [.u8(1)])),
				jsonRepresentation: """
				{"type":"Enum","variant":{"type":"U8","discriminator":"1"},"fields":[{"type":"U8","value":"1"}]}
				"""
			),
			(
				value: Value_.some(.init(Value_.string("Component"))),
				jsonRepresentation: """
				{"type":"Some","value":{"type":"String","value":"Component"}}
				"""
			),
			(
				value: Value_.none,
				jsonRepresentation: """
				{"type":"None"}
				"""
			),
			(
				value: Value_.ok(.init(Value_.string("Component"))),
				jsonRepresentation: """
				{"type":"Ok","value":{"type":"String","value":"Component"}}
				"""
			),
			(
				value: Value_.err(.init(Value_.string("Component"))),
				jsonRepresentation: """
				{"type":"Err","value":{"type":"String","value":"Component"}}
				"""
			),

			try (
				value: Value_.array(.init(elementKind: .string, elements: [.string("World, Hello!")])),
				jsonRepresentation: """
				{"type":"Array","element_kind":"String","elements":[{"type":"String","value":"World, Hello!"}]}
				"""
			),
			(
				value: Value_.tuple(.init(values: [
					.i64(19),
					.i8(19),
				])),
				jsonRepresentation: """
				{"type":"Tuple","elements":[{"type":"I64","value":"19"},{"type":"I8","value":"19"}]}
				"""
			),
			(
				value: Value_.map(.init(
					keyValueKind: .string,
					valueValueKind: .u16,
					entries: [
						[
							Value_.string("Hello,World!"),
							Value_.u16(919),
						],
						[
							Value_.string("World,Hello!"),
							Value_.u16(111),
						],
					]
				)),
				jsonRepresentation: """
				{"entries":[[{"type":"String","value":"Hello,World!"},{"type":"U16","value":"919"}],[{"type":"String","value":"World,Hello!"},{"type":"U16","value":"111"}]],"type":"Map","key_value_kind":"String","value_value_kind":"U16"}
				"""
			),
			(
				value: Value_.decimal(.init(value: "1923319912.102221313")),
				jsonRepresentation: """
				{"type":"Decimal","value":"1923319912.102221313"}
				"""
			),
			(
				value: Value_.preciseDecimal(.init(value: "1923319912.102221313")),
				jsonRepresentation: """
				{"type":"PreciseDecimal","value":"1923319912.102221313"}
				"""
			),

			(
				value: Value_.componentAddress(.init(address: "account_sim1qvqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqg5cu7q")),
				jsonRepresentation: """
				{"type":"ComponentAddress","address":"account_sim1qvqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqg5cu7q"}
				"""
			),
			(
				value: Value_.resourceAddress(.init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety")),
				jsonRepresentation: """
				{"type":"ResourceAddress","address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"}
				"""
			),
			(
				value: Value_.packageAddress(.init(address: "package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq")),
				jsonRepresentation: """
				{"type":"PackageAddress","address":"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq"}
				"""
			),
			try (
				value: Value_.hash(.init(hex: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")),
				jsonRepresentation: """
				{"type":"Hash","value":"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"}
				"""
			),
			try (
				value: Value_.ecdsaSecp256k1PublicKey(.init(hex: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798")),
				jsonRepresentation: """
				{"type":"EcdsaSecp256k1PublicKey","public_key":"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"}
				"""
			),
			try (
				value: Value_.eddsaEd25519PublicKey(.init(hex: "4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29")),
				jsonRepresentation: """
				{"type":"EddsaEd25519PublicKey","public_key":"4cb5abf6ad79fbf5abbccafcc269d85cd2651ed4b885b5869f241aedf0a5ba29"}
				"""
			),

			try (
				value: Value_.ecdsaSecp256k1Signature(.init(hex: "0079224ea514206706298d8d620f660828f7987068d6d02757e6f3cbbf4a51ab133395db69db1bc9b2726dd99e34efc252d8258dcb003ebaba42be349f50f7765e")),
				jsonRepresentation: """
				{"type":"EcdsaSecp256k1Signature","signature":"0079224ea514206706298d8d620f660828f7987068d6d02757e6f3cbbf4a51ab133395db69db1bc9b2726dd99e34efc252d8258dcb003ebaba42be349f50f7765e"}
				"""
			),
			try (
				value: Value_.eddsaEd25519Signature(.init(hex: "ce993adc51111309a041faa65cbcf1154d21ed0ecdc2d54070bc90b9deb744aa8605b3f686fa178fba21070b4a4678e54eee3486a881e0e328251cd37966de09")),
				jsonRepresentation: """
				{"type":"EddsaEd25519Signature","signature":"ce993adc51111309a041faa65cbcf1154d21ed0ecdc2d54070bc90b9deb744aa8605b3f686fa178fba21070b4a4678e54eee3486a881e0e328251cd37966de09"}
				"""
			),
			(
				value: Value_.bucket(.init(stringLiteral: "xrd_bucket")),
				jsonRepresentation: """
				{"type":"Bucket","identifier":{"type":"String","value":"xrd_bucket"}}
				"""
			),
			(
				value: Value_.proof(.init(stringLiteral: "xrd_bucket")),
				jsonRepresentation: """
				{"type":"Proof","identifier":{"type":"String","value":"xrd_bucket"}}
				"""
			),
			(
				value: Value_.bucket(.init(integerLiteral: 1)),
				jsonRepresentation: """
				{"type":"Bucket","identifier":{"type":"U32","value":"1"}}
				"""
			),
			(
				value: Value_.proof(.init(integerLiteral: 1)),
				jsonRepresentation: """
				{"type":"Proof","identifier":{"type":"U32","value":"1"}}
				"""
			),
			(
				value: Value_.nonFungibleLocalId(.integer(114_441_894_733_333)),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"114441894733333"}}
				"""
			),
			(
				value: Value_.nonFungibleLocalId(.uuid("238510006928098330588051703199685491739")),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"UUID","value":"238510006928098330588051703199685491739"}}
				"""
			),
			(
				value: Value_.nonFungibleLocalId(.string("hello_world")),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"String","value":"hello_world"}}
				"""
			),
			(
				value: Value_.nonFungibleLocalId(.bytes([0x10, 0xA2, 0x31, 0x01])),
				jsonRepresentation: """
				{"type":"NonFungibleLocalId","value":{"type":"Bytes","value":"10a23101"}}
				"""
			),
			(
				value: Value_.nonFungibleGlobalId(.init(
					resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"),
					nonFungibleLocalId: .integer(114_441_894_733_333)
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"ResourceAddress","address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"114441894733333"}}}
				"""
			),
			(
				value: Value_.nonFungibleGlobalId(.init(
					resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"),
					nonFungibleLocalId: .uuid("238510006928098330588051703199685491739")
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"ResourceAddress","address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"UUID","value":"238510006928098330588051703199685491739"}}}
				"""
			),
			(
				value: Value_.nonFungibleGlobalId(.init(
					resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"),
					nonFungibleLocalId: .string("hello_world")
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"ResourceAddress","address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"String","value":"hello_world"}}}
				"""
			),
			(
				value: Value_.nonFungibleGlobalId(.init(
					resourceAddress: .init(address: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"),
					nonFungibleLocalId: .bytes([0x10, 0xA2, 0x31, 0x01])
				)),
				jsonRepresentation: """
				{"type":"NonFungibleGlobalId","resource_address":{"type":"ResourceAddress","address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"},"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Bytes","value":"10a23101"}}}
				"""
			),

			try (
				value: Value_.blob(.init(hex: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")),
				jsonRepresentation: """
				{"type":"Blob","hash":"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"}
				"""
			),
			(
				value: Value_.expression(.init(value: "ENTIRE_AUTH_ZONE")),
				jsonRepresentation: """
				{"type":"Expression","value":"ENTIRE_AUTH_ZONE"}
				"""
			),
			(
				value: Value_.expression(.init(value: "ENTIRE_WORKTOP")),
				jsonRepresentation: """
				{"type":"Expression","value":"ENTIRE_WORKTOP"}
				"""
			),
			try (
				value: Value_.bytes(.init(hex: "1219122008")),
				jsonRepresentation: """
				{"type":"Bytes","value":"1219122008"}
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
			let decodedValue = try decoder.decode(Value_.self, from: jsonRepresentation.data(using: .utf8)!)

			// Assert
			XCTAssertEqual(value, decodedValue)
		}
	}
}
