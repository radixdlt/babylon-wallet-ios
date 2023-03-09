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

		// Arrange
		let testVectors: [(value: Instruction, jsonRepresentation: String)] = [
			(
				value: .callFunction(.init(
					packageAddress: PackageAddress(address: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8"),
					blueprintName: "Faucet",
					functionName: "new",
					arguments: [
						.decimal(.init(value: "1")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"1"}],"blueprint_name":{"type":"String","value":"Faucet"},"function_name":{"type":"String","value":"new"},"instruction":"CALL_FUNCTION","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"PackageAddress"}}
				"""
			),
			(
				value: .callFunction(.init(
					packageAddress: Address_(address: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8"),
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
					receiver: Address_(address: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
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
					receiver: ComponentAddress(address: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
					methodName: "free",
					arguments: [
						.decimal(.init(value: "1")),
					]
				)),
				jsonRepresentation: """
				{"arguments":[{"type":"Decimal","value":"1"}],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: Address_(address: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
					methodName: "free"
				)),
				jsonRepresentation: """
				{"arguments":[],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"Address"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .callMethod(.init(
					receiver: ComponentAddress(address: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
					methodName: "free"
				)),
				jsonRepresentation: """
				{"arguments":[],"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"CALL_METHOD","method_name":{"type":"String","value":"free"}}
				"""
			),
			(
				value: .takeFromWorktop(.init(
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"TAKE_FROM_WORKTOP","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktop(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"TAKE_FROM_WORKTOP","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .takeFromWorktopByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"TAKE_FROM_WORKTOP_BY_AMOUNT","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .takeFromWorktopByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"TAKE_FROM_WORKTOP_BY_AMOUNT","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .takeFromWorktopByIds(.init(
					[.integer(1)],
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					bucket: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"TAKE_FROM_WORKTOP_BY_IDS","into_bucket":{"identifier":{"type":"String","value":"ident"},"type":"Bucket"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .takeFromWorktopByIds(.init(
					[.integer(1)],
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
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
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm")
				)),
				jsonRepresentation: """
				{"instruction":"ASSERT_WORKTOP_CONTAINS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContains(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm")
				)),
				jsonRepresentation: """
				{"instruction":"ASSERT_WORKTOP_CONTAINS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .assertWorktopContainsByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"ASSERT_WORKTOP_CONTAINS_BY_AMOUNT","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByAmount(.init(
					amount: .init(value: "1"),
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"ASSERT_WORKTOP_CONTAINS_BY_AMOUNT","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .assertWorktopContainsByIds(.init(
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					ids: [.integer(1)]
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"ASSERT_WORKTOP_CONTAINS_BY_IDS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .assertWorktopContainsByIds(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					ids: [.integer(1)]
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"ASSERT_WORKTOP_CONTAINS_BY_IDS","resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
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
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_PROOF_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZone(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"instruction":"CREATE_PROOF_FROM_AUTH_ZONE","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByAmount(.init(
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					amount: .init(value: "1"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByAmount(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					amount: .init(value: "1"),
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"amount":{"type":"Decimal","value":"1"},"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_AMOUNT","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByIds(.init(
					resourceAddress: Address_(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					ids: [.integer(1)],
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"Address"}}
				"""
			),
			(
				value: .createProofFromAuthZoneByIds(.init(
					resourceAddress: ResourceAddress(address: "resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm"),
					ids: [.integer(1)],
					intoProof: .init(stringLiteral: "ident")
				)),
				jsonRepresentation: """
				{"ids":[{"type":"NonFungibleLocalId","value":{"type":"Integer","value":"1"}}],"instruction":"CREATE_PROOF_FROM_AUTH_ZONE_BY_IDS","into_proof":{"identifier":{"type":"String","value":"ident"},"type":"Proof"},"resource_address":{"address":"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy99qqm","type":"ResourceAddress"}}
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
			(
				value: .publishPackage(.init(
					code: try .init(hex: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"),
					schema: try .init(hex: "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"),
					royaltyConfig: Map_(keyValueKind: .string, valueValueKind: .tuple, entries: []),
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: accessRules
				)),
				jsonRepresentation: """
				{"access_rules":{"elements":[{"key_value_kind":"Tuple","type":"Map","value_value_kind":"Enum"},{"key_value_kind":"String","type":"Map","value_value_kind":"Enum"},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"key_value_kind":"Tuple","type":"Map","value_value_kind":"Enum"},{"key_value_kind":"String","type":"Map","value_value_kind":"Enum"},{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}],"type":"Tuple"},"code":{"hash":"01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b","type":"Blob"},"instruction":"PUBLISH_PACKAGE","metadata":{"key_value_kind":"String","type":"Map","value_value_kind":"String"},"royalty_config":{"key_value_kind":"String","type":"Map","value_value_kind":"Tuple"},"schema":{"hash":"01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b","type":"Blob"}}
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
					entityAddress: .componentAddress("component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
					key: "name",
					value: "deadbeef"
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"SET_METADATA","key":{"type":"String","value":"name"},"value":{"type":"String","value":"deadbeef"}}
				"""
			),
			(
				value: .setPackageRoyaltyConfig(.init(
					packageAddress: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8",
					royaltyConfig: .init(
						keyValueKind: .string,
						valueValueKind: .tuple,
						entries: []
					)
				)),
				jsonRepresentation: """
				{"instruction":"SET_PACKAGE_ROYALTY_CONFIG","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"PackageAddress"},"royalty_config":{"key_value_kind":"String","type":"Map","value_value_kind":"Tuple"}}
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
				{"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"SET_COMPONENT_ROYALTY_CONFIG","royalty_config":{"elements":[{"key_value_kind":"String","type":"Map","value_value_kind":"U32"},{"type":"U32","value":"1"}],"type":"Tuple"}}
				"""
			),
			(
				value: .claimPackageRoyalty(.init(packageAddress: "package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8")),
				jsonRepresentation: """
				{"instruction":"CLAIM_PACKAGE_ROYALTY","package_address":{"address":"package_rdx1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqzrhqe8","type":"PackageAddress"}}
				"""
			),
			(
				value: .claimComponentRoyalty(.init(componentAddress: "component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt")),
				jsonRepresentation: """
				{"component_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"CLAIM_COMPONENT_ROYALTY"}
				"""
			),
			(
				value: .setMethodAccessRule(.init(
					entityAddress: .componentAddress("component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt"),
					key: Tuple(values: [.enum(.init(.u8(0))), .string("free")]),
					rule: Enum(.u8(0), fields: [])
				)),
				jsonRepresentation: """
				{"entity_address":{"address":"component_rdx1qtkryz5scup945usk39qjc2yjh6l5zsyuh8t7v5pk0tsrdcazt","type":"ComponentAddress"},"instruction":"SET_METHOD_ACCESS_RULE","key":{"elements":[{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},{"type":"String","value":"free"}],"type":"Tuple"},"rule":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}}}
				"""
			),
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
				{"entries":{"key_value_kind":"NonFungibleLocalId","type":"Map","value_value_kind":"Tuple"},"instruction":"MINT_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .mintUuidNonFungible(.init(
					resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety",
					entries: try .array(.init(elementKind: .tuple,
					                          elements: [
					                          	.tuple(.init([Tuple([]), Tuple([])])),
					                          	.tuple(.init([Tuple([]), Tuple([])])),
					                          ]))
				)),
				jsonRepresentation: """
				{"entries":{"element_kind":"Tuple","elements":[{"elements":[{"elements":[],"type":"Tuple"},{"elements":[],"type":"Tuple"}],"type":"Tuple"},{"elements":[{"elements":[],"type":"Tuple"},{"elements":[],"type":"Tuple"}],"type":"Tuple"}],"type":"Array"},"instruction":"MINT_UUID_NON_FUNGIBLE","resource_address":{"address":"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqz8qety","type":"ResourceAddress"}}
				"""
			),
			(
				value: .createFungibleResource(.init(
					divisibility: 18,
					metadata: .init(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: .init(keyValueKind: .enum, valueValueKind: .tuple, entries: [])
				)),
				jsonRepresentation: """
				{"access_rules":{"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"divisibility":{"type":"U8","value":"18"},"instruction":"CREATE_FUNGIBLE_RESOURCE","metadata":{"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
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
				{"access_rules":{"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"divisibility":{"type":"U8","value":"18"},"initial_supply":{"type":"Decimal","value":"1"},"instruction":"CREATE_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY","metadata":{"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createNonFungibleResource(.init(
					idType: Enum(.u8(0), fields: []),
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: Map_(keyValueKind: .enum, valueValueKind: .tuple, entries: [])
				)),
				jsonRepresentation: """
				{"access_rules":{"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"id_type":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"instruction":"CREATE_NON_FUNGIBLE_RESOURCE","metadata":{"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
				"""
			),
			(
				value: .createNonFungibleResourceWithInitialSupply(.init(
					idType: Enum(.u8(0), fields: []),
					metadata: Map_(keyValueKind: .string, valueValueKind: .string, entries: []),
					accessRules: Map_(keyValueKind: .enum, valueValueKind: .tuple, entries: []),
					initialSupply: .decimal(.init(value: "1"))
				)),
				jsonRepresentation: """
				{"access_rules":{"key_value_kind":"Enum","type":"Map","value_value_kind":"Tuple"},"id_type":{"type":"Enum","variant":{"discriminator":"0","type":"U8"}},"initial_supply":{"type":"Decimal","value":"1"},"instruction":"CREATE_NON_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY","metadata":{"key_value_kind":"String","type":"Map","value_value_kind":"String"}}
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
			(
				value: try .createValidator(.init(
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
