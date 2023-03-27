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
		let accessRules = Tuple {
			Map_(keyValueKind: .tuple, valueValueKind: .enum, entries: [])
			Map_(keyValueKind: .string, valueValueKind: .enum, entries: [])
			Enum(.u8(0), fields: [])
			Map_(keyValueKind: .tuple, valueValueKind: .enum, entries: [])
			Map_(keyValueKind: .string, valueValueKind: .enum, entries: [])
			Enum(.u8(0), fields: [])
		}

		let schema = try Tuple {
			try Tuple {
				try Array_(elementKind: .enum, elements: [])
				try Array_(elementKind: .tuple, elements: [])
				try Array_(elementKind: .enum, elements: [])
			}
			Enum(.u8(0), fields: [.u8(64)])
			try Array_(elementKind: .string, elements: [])
		}

		// Arrange
		let testVectors: [(value: Instruction, jsonRepresentation: String)] = [
			(
				value: .callFunction(.init(
					packageAddress: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8",
					blueprintName: "Faucet",
					functionName: "new",
					arguments: [
						.decimal(.init(value: "1")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"1"}],"blueprint_name":{"type":"String","value":"Faucet"},"function_name":{"type":"String","value":"new"},"instruction":"CALL_FUNCTION","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"Address"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					methodName: "free",
					arguments: [
						.decimal(.init(value: "1")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"1"}],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					methodName: "free"
				)),
				jsonRepresentation: """
				{"arguments":[],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					methodName: "free"
				)),
				jsonRepresentation: """
				{"arguments":[],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .takeFromWorktop(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"TAKE_FROM_WORKTOP","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktop(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"TAKE_FROM_WORKTOP","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktopByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"TAKE_FROM_WORKTOP_BY_AMOUNT","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktopByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"TAKE_FROM_WORKTOP_BY_AMOUNT","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktopByIds(.init(
					[.integer(1)],
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"TAKE_FROM_WORKTOP_BY_IDS","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktopByIds(.init(
					[.integer(1)],
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"TAKE_FROM_WORKTOP_BY_IDS","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .returnToWorktop(.init(
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"instruction":"RETURN_TO_WORKTOP"}
				"""
			),
			(
				value: .assertWorktopContains(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"
				)),
				jsonRepresentation: """
				{"instruction":"ASSERT_WORKTOP_CONTAINS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContains(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"
				)),
				jsonRepresentation: """
				{"instruction":"ASSERT_WORKTOP_CONTAINS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"ASSERT_WORKTOP_CONTAINS_BY_AMOUNT","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"ASSERT_WORKTOP_CONTAINS_BY_AMOUNT","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByIds(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					ids: [.integer(1)]
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"ASSERT_WORKTOP_CONTAINS_BY_IDS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByIds(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					ids: [.integer(1)]
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"ASSERT_WORKTOP_CONTAINS_BY_IDS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
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
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_PROOF_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZone(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_PROOF_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByAmount(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					amount: .init(value: "1"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByAmount(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					amount: .init(value: "1"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByIds(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					ids: [.integer(1)],
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByIds(.init(
					resourceAddress: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm",
					ids: [.integer(1)],
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromBucket(.init(
					bucket: Bucket(.string("bucket")),
					proof: Proof(.string("Proof"))
				)),
				jsonRepresentation: """
				{"bucket":{"identifier":{"type":"String","value":"bucket"},"type":"Bucket"},"instruction":"CREATE_PROOF_FROM_BUCKET","into_proof":{"identifier":{"type":"String","value":"Proof"},"type":"Proof"}}
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
				value: .burnResource(.init(
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"instruction":"BURN_RESOURCE"}
				"""
			),
			(
				value: .dropAllProofs(.init()),
				jsonRepresentation: """
				{"instruction":"DROP_ALL_PROOFS"}
				"""
			),
			try (
				value: .publishPackage(.init(
					code: Blob(hex: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"),
					schema: Blob(hex: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"),
					royaltyConfig: Map_(keyValueKind: .string, valueValueKind: .tuple, entries: []),
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: accessRules
				)),
				jsonRepresentation: """
				{"access_rules":{"elements":[{"entries":[],"key_value_kind":"Tuple","type":"Map","value_value_kind":"Enum"},{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"Enum"},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"entries":[],"key_value_kind":"Tuple","type":"Map","value_value_kind":"Enum"},{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"Enum"},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}],"type":"Tuple"},"code":{"hash":"01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b","type":"Blob"},"instruction":"PUBLISH_PACKAGE","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"},"royalty_config":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"Tuple"},"schema":{"hash":"01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b","type":"Blob"}}
				"""
			),
			try (
				value: .recallResource(.init(
					vault_id: .init(hex: "a9d55474c4fe9b04a5f39dc8164b9a9c22dae66a34e1417162c327912cc492"),
					amount: .init(value: "1")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"RECALL_RESOURCE","vault_id":{"type":"Bytes","value":"a9d55474c4fe9b04a5f39dc8164b9a9c22dae66a34e1417162c327912cc492"}}
				"""
			),
			(
				value: .setMetadata(.init(
					entityAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					key: "name",
					value: Enum(.u8(0), fields: [.enum(.init(.u8(0), fields: [.string("deadbeef")]))])
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"SET_METADATA","key":{"type":"String","value":"name"},"value":{"fields":[{"fields":[{"type":"String","value":"deadbeef"}],"type":"Enum","variant":{"discriminator":"0","type":"U8"}}],"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
			(
				value: .removeMetadata(.init(
					entityAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					key: "name"
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"REMOVE_METADATA","key":{"type":"String","value":"name"}}
				"""
			),
			(
				value: .setPackageRoyaltyConfig(.init(
					packageAddress: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8",
					royaltyConfig: Map_(
						keyValueKind: .string,
						valueValueKind: .tuple,
						entries: []
					)
				)),
				jsonRepresentation: """
				{"instruction":"SET_PACKAGE_ROYALTY_CONFIG","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"Address"},"royalty_config":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"Tuple"}}
				"""
			),
			(
				value: .setComponentRoyaltyConfig(.init(
					componentAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
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
				{"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"SET_COMPONENT_ROYALTY_CONFIG","royalty_config":{"elements":[{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"U32"},{"type":"U32","value":"1"}],"type":"Tuple"}}
				"""
			),
			(
				value: .claimPackageRoyalty(.init(packageAddress: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8")),
				jsonRepresentation: """
				{"instruction":"CLAIM_PACKAGE_ROYALTY","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"Address"}}
				"""
			),
			(
				value: .claimComponentRoyalty(.init(componentAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt")),
				jsonRepresentation: """
				{"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"CLAIM_COMPONENT_ROYALTY"}
				"""
			),
			(
				value: .setMethodAccessRule(.init(
					entityAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt",
					key: Tuple(values: [.enum(.init(.u8(0))), .string("free")]),
					rule: Enum(.u8(0), fields: [])
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"SET_METHOD_ACCESS_RULE","key":{"elements":[{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"type":"String","value":"free"}],"type":"Tuple"},"rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
			(
				value: .mintFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					amount: .init(value: "1")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"MINT_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"Address"}}
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
				{"entries":{"entries":[],"key_value_kind":"NonFungibleLocalId","type":"Map","value_value_kind":"Tuple"},"instruction":"MINT_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"Address"}}
				"""
			),
			try (
				value: .mintUuidNonFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					entries: .array(.init(elementKind: .tuple,
					                      elements: [
					                      	.tuple(.init([Tuple([]), Tuple([])])),
					                      	.tuple(.init([Tuple([]), Tuple([])])),
					                      ]))
				)),
				jsonRepresentation: """
				{"entries":{"element_kind":"Tuple","elements":[{"elements":[{"elements":[],"type":"Tuple"},{"elements":[],"type":"Tuple"}],"type":"Tuple"},{"elements":[{"elements":[],"type":"Tuple"},{"elements":[],"type":"Tuple"}],"type":"Tuple"}],"type":"Array"},"instruction":"MINT_UUID_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"Address"}}
				"""
			),
			(
				value: .createFungibleResource(.init(
					divisibility: 18,
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: .init(keyValueKind: .enum, valueValueKind: .tuple, entries: [])
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"divisibility":{"type":"U8","value":"18"},"instruction":"CREATE_FUNGIBLE_RESOURCE","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createFungibleResourceWithInitialSupply(.init(
					divisibility: 18,
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: .init(keyValueKind: .enum, valueValueKind: .tuple, entries: []),
					initialSupply: .decimal(.init(value: "1"))
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"divisibility":{"type":"U8","value":"18"},"initial_supply":{"type":"Decimal","value":"1"},"instruction":"CREATE_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createNonFungibleResource(.init(
					idType: Enum(.u8(0), fields: []),
					schema: schema,
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: Map_(keyValueKind: .enum, valueValueKind: .tuple, entries: [])
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"id_type":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"CREATE_NON_FUNGIBLE_RESOURCE","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"},"schema":{"elements":[{"elements":[{"element_kind":"Enum","elements":[],"type":"Array"},{"element_kind":"Tuple","elements":[],"type":"Array"},{"element_kind":"Enum","elements":[],"type":"Array"}],"type":"Tuple"},{"fields":[{"type":"U8","value":"64"}],"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"element_kind":"String","elements":[],"type":"Array"}],"type":"Tuple"}}
				"""
			),
			(
				value: .createNonFungibleResourceWithInitialSupply(.init(
					idType: Enum(.u8(0), fields: []),
					schema: schema,
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: Map_(keyValueKind: .enum, valueValueKind: .tuple, entries: []),
					initialSupply: .decimal(.init(value: "1"))
				)),
				jsonRepresentation: """
				{"access_rules":{"entries":[],"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"id_type":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"initial_supply":{"type":"Decimal","value":"1"},"instruction":"CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY","metadata":{"entries":[],"key_value_kind":"String","type":"Map","value_value_kind":"String"},"schema":{"elements":[{"elements":[{"element_kind":"Enum","elements":[],"type":"Array"},{"element_kind":"Tuple","elements":[],"type":"Array"},{"element_kind":"Enum","elements":[],"type":"Array"}],"type":"Tuple"},{"fields":[{"type":"U8","value":"64"}],"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"element_kind":"String","elements":[],"type":"Array"}],"type":"Tuple"}}
				"""
			),
			(
				value: .createAccessController(.init(
					controlledAsset: .init(identifier: .string("ident")),
					ruleSet: .init(values: [
						.enum(.init(.u8(0))),
						.enum(.init(.u8(0))),
						.enum(.init(.u8(0))),
					]),
					timedRecoveryDelayInMinutes: .some(.init(.u32(1)))
				)),
				jsonRepresentation: """
				{"controlled_asset":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"instruction":"CREATE_ACCESS_CONTROLLER","rule_set":{"elements":[{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}],"type":"Tuple"},"timed_recovery_delay_in_minutes":{"type":"Some","value":{"type":"U32","value":"1"}}}
				"""
			),
			(
				value: .createIdentity(.init(accessRule: .init(.u8(0), fields: []))),
				jsonRepresentation: """
				{"access_rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"CREATE_IDENTITY"}
				"""
			),
			(
				value: .assertAccessRule(.init(accessRule: .init(.u8(0), fields: []))),
				jsonRepresentation: """
				{"access_rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"ASSERT_ACCESS_RULE"}
				"""
			),
			try (
				value: .createValidator(.init(
					key: Bytes(hex: "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"),
					ownerAccessRule: Enum(.u8(0))
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_VALIDATOR","key":{"type":"Bytes","value":"0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"},"owner_access_rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
			(
				value: .createAccount(.init(
					withdrawRule: Enum(.u8(0))
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_ACCOUNT","withdraw_rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
			(
				value: .dropProof(.init(stringLiteral: "ident")),
				jsonRepresentation: """
				{"instruction":"DROP_PROOF","proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"}}
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
