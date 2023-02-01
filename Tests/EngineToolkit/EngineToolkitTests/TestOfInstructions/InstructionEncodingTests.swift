import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class InstructionEncodingTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test_value_encoding_and_decoding() throws {
		// Arrange
		let testVectors: [(value: Instruction, jsonRepresentation: String)] = [
			(
				value: .callFunction(.init(
					packageAddress: "package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq",
					blueprintName: "HelloWorld",
					functionName: "world_hello",
					arguments: [
						.decimal(.init(value: "129333")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"129333"}],"blueprint_name":{"type":"String","value":"HelloWorld"},"function_name":{"type":"String","value":"world_hello"},"instruction":"CALL_FUNCTION","package_address":{"address":"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq","type":"PackageAddress"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: "component_sim1qgqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8ecz5v",
					methodName: "remove_user",
					arguments: [
						.decimal(.init(value: "12")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"12"}],"component_address":{"address":"component_sim1qgqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq8ecz5v","type":"ComponentAddress"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"remove_user"}}
				"""
			),
			(
				value: .takeFromWorktop(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"TAKE_FROM_WORKTOP","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .takeFromWorktopByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"TAKE_FROM_WORKTOP_BY_AMOUNT","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .takeFromWorktopByIds(.init(
					[
						.integer(1),
					],
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"TAKE_FROM_WORKTOP_BY_IDS","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .returnToWorktop(.init(bucket: .init(stringLiteral: "ident"))),
				jsonRepresentation: """
				{"bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"instruction":"RETURN_TO_WORKTOP"}
				"""
			),
			(
				value: .assertWorktopContains(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"
				)),
				jsonRepresentation: """
				{"instruction":"ASSERT_WORKTOP_CONTAINS","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .assertWorktopContainsByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety"
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"ASSERT_WORKTOP_CONTAINS_BY_AMOUNT","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .assertWorktopContainsByIds(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					ids: [
						.integer(1),
					]
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"ASSERT_WORKTOP_CONTAINS_BY_IDS","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .popFromAuthZone(.init(proof: .init(stringLiteral: "ident"))),
				jsonRepresentation: """
				{"instruction":"POP_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"}}
				"""
			),
			(
				value: .pushToAuthZone(.init(proof: .init(stringLiteral: "ident"))),
				jsonRepresentation: """
				{"instruction":"PUSH_TO_AUTH_ZONE","proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"}}
				"""
			),
			(
				value: .clearAuthZone(.init()),
				jsonRepresentation: """
				{"instruction":"CLEAR_AUTH_ZONE"}
				"""
			),
			(
				value: .createProofFromAuthZone(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_PROOF_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByAmount(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					amount: .init(value: "1"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByIds(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					ids: [
						.integer(1),
					],
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .cloneProof(.init(
					from: .init(stringLiteral: "ident"),
					to: .init(stringLiteral: "ident2")
				)),
				jsonRepresentation: """
				{"instruction":"CLONE_PROOF","into_proof":{"identifier":{"type":"String","value":"ident2"},"type":"Proof"},"proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"}}
				"""
			),
			(
				value: .dropProof(.init(stringLiteral: "ident")),
				jsonRepresentation: """
				{"instruction":"DROP_PROOF","proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"}}
				"""
			),
			(
				value: .dropAllProofs(.init()),
				jsonRepresentation: """
				{"instruction":"DROP_ALL_PROOFS"}
				"""
			),
			(
				value: .publishPackageWithOwner(.init(
					code: try .init(hex: "36dae540b7889956f1f1d8d46ba23e5e44bf5723aef2a8e6b698686c02583618"),
					abi: try .init(hex: "15e8699a6d63a96f66f6feeb609549be2688b96b02119f260ae6dfd012d16a5d"),
					ownerBadge: .init(
						resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
						nonFungibleLocalId: .integer(1)
					)
				)),
				jsonRepresentation: """
				{"abi":{"hash":"15e8699a6d63a96f66f6feeb609549be2688b96b02119f260ae6dfd012d16a5d","type":"Blob"},"code":{"hash":"36dae540b7889956f1f1d8d46ba23e5e44bf5723aef2a8e6b698686c02583618","type":"Blob"},"instruction":"PUBLISH_PACKAGE_WITH_OWNER","owner_badge":{"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"},"type":"NonFungibleGlobalId"}}
				"""
			),
			(
				value: .burnResource(.init(
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"instruction":"BURN_RESOURCE"}
				"""
			),
			(
				value: try .recallResource(.init(
					vault_id: .init(hex: "776e134adba9d55474c4fe9b04a5f39dc8164b9a9c22dae66a34e1417162c327912cc492"),
					amount: .init(value: "1")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"RECALL_RESOURCE","vault_id":{"type":"Bytes","value":"776e134adba9d55474c4fe9b04a5f39dc8164b9a9c22dae66a34e1417162c327912cc492"}}
				"""
			),
			(
				value: .setMetadata(.init(
					entityAddress: .componentAddress("component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr"),
					key: "name",
					value: "deadbeef"
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr","type":"ComponentAddress"},"instruction":"SET_METADATA","key":{"type":"String","value":"name"},"value":{"type":"String","value":"deadbeef"}}
				"""
			),
			(
				value: .setMetadata(.init(
					entityAddress: .packageAddress("package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq"),
					key: "name",
					value: "deadbeef"
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq","type":"PackageAddress"},"instruction":"SET_METADATA","key":{"type":"String","value":"name"},"value":{"type":"String","value":"deadbeef"}}
				"""
			),
			(
				value: .setComponentRoyaltyConfig(.init(
					componentAddress: "component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr",
					royaltyConfig: .tuple(.init(values: [
						.map(.init(
							keyValueKind: .string,
							valueValueKind: .u32,
							entries: []
						)),
						.u32(1),
					]))
				)),
				jsonRepresentation: """
				{"component_address":{"address":"component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr","type":"ComponentAddress"},"instruction":"SET_COMPONENT_ROYALTY_CONFIG","royalty_config":{"elements":[{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"U32"},{"type":"U32","value":"1"}],"type":"Tuple"}}
				"""
			),
			(
				value: .setPackageRoyaltyConfig(.init(
					packageAddress: "package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq",
					royaltyConfig: .init(
						keyValueKind: .string,
						valueValueKind: .tuple,
						entries: []
					)
				)),
				jsonRepresentation: """
				{"instruction":"SET_PACKAGE_ROYALTY_CONFIG","package_address":{"address":"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq","type":"PackageAddress"},"royalty_config":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"Tuple"}}
				"""
			),
			(
				value: .claimComponentRoyalty(.init(componentAddress: "component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr")),
				jsonRepresentation: """
				{"component_address":{"address":"component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr","type":"ComponentAddress"},"instruction":"CLAIM_COMPONENT_ROYALTY"}
				"""
			),
			(
				value: .claimPackageRoyalty(.init(packageAddress: "package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq")),
				jsonRepresentation: """
				{"instruction":"CLAIM_PACKAGE_ROYALTY","package_address":{"address":"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxrmwtq","type":"PackageAddress"}}
				"""
			),
			//            (
			//                value: .setMethodAccessRule(.init(
			//                    entityAddress: .componentAddress("component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr"),
			//                    index: 0,
			//                    key: "get_token",
			//                    rule: .init(.u8(0), fields: [])
			//                )),
			//                jsonRepresentation: """
			//                {"entity_address":{"type":"ComponentAddress","address":"component_sim1qgehpqdhhr62xh76wh6gppnyn88a0uau68epljprvj3sxknsqr"},"index":{"type":"U32","value":"0"},"instruction":"SET_METHOD_ACCESS_RULE","key":{"type":"Enum","variant":{"type":"U8","discriminator":"0"},"fields":[{"type":"String","value":"get_token"}]},"rule":{"type":"Enum","variant":{"type":"U8","discriminator":"0"},"fields":[]}}
			//                """
			//            ),
			(
				value: .mintFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					amount: .init(value: "1")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"MINT_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .mintNonFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					entries: .map(.init(
						keyValueKind: .nonFungibleLocalId,
						valueValueKind: .tuple,
						entries: []
					))
				)),
				jsonRepresentation: """
				{"entries":{"entries":[],"key_value_kind":"NonFungibleLocalId","type":"Map","value_value_kind":"Tuple"},"instruction":"MINT_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .mintUuidNonFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					entries: try .array(.init(elementKind: .tuple, elements: []))
				)),
				jsonRepresentation: """
				{"entries":{"element_kind":"Tuple","elements":[],"type":"Array"},"instruction":"MINT_UUID_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createFungibleResource(.init(
					divisibility: 18,
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: .init(keyValueKind: .enum, valueValueKind: .tuple, entries: []),
					initialSupply: .none
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"divisibility":{"type":"U8","value":"18"},"initial_supply":{"type":"None"},"instruction":"CREATE_FUNGIBLE_RESOURCE","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createFungibleResourceWithOwner(.init(
					divisibility: 18,
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					ownerBadge: .init(
						resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
						nonFungibleLocalId: .integer(1)
					),
					initialSupply: .none
				)),
				jsonRepresentation: """
				{"divisibility":{"type":"U8","value":"18"},"initial_supply":{"type":"None"},"instruction":"CREATE_FUNGIBLE_RESOURCE_WITH_OWNER","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"},"owner_badge":{"non_fungible_local_id":{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}},"resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"},"type":"NonFungibleGlobalId"}}
				"""
			),
			(
				value: .createNonFungibleResource(.init(
					idType: .init(.u8(0), fields: []),
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: .init(keyValueKind: .enum, valueValueKind: .tuple, entries: []),
					initialSupply: .none
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"id_type":{"fields":[],"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"initial_supply":{"type":"None"},"instruction":"CREATE_NON_FUNGIBLE_RESOURCE","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createIdentity(.init(accessRule: .init(.u8(0), fields: []))),
				jsonRepresentation: """
				{"access_rule":{"fields":[],"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"CREATE_IDENTITY"}
				"""
			),
			(
				value: .assertAccessRule(.init(accessRule: .init(.u8(0), fields: []))),
				jsonRepresentation: """
				{"access_rule":{"fields":[],"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"ASSERT_ACCESS_RULE"}
				"""
			),
			(
				value: try .createValidator(.init(
					key: .init(hex: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"),
					ownerAccessRule: .init(.u8(0))
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_VALIDATOR","key":{"public_key":"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798","type":"EcdsaSecp256k1PublicKey"},"owner_access_rule":{"fields":[],"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
		]

		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]

		for (value, jsonRepresentation) in testVectors {
			// Act
			let string = try XCTUnwrap(String(data: encoder.encode(value), encoding: .utf8))

			// Assert
			XCTAssertNoDifference(string, jsonRepresentation)

			// Act
			let decodedValue = try decoder.decode(Instruction.self, from: jsonRepresentation.data(using: .utf8)!)

			// Assert
			XCTAssertEqual(value, decodedValue)
		}
	}
}
