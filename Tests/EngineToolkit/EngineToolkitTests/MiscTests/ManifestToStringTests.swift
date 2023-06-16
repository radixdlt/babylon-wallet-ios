import Cryptography
@testable import EngineToolkit
import TestingPrelude

// MARK: - ManifestToStringTests
final class ManifestToStringTests: TestCase {
	private let engineToolkit = RadixEngine.instance

	override func setUp() {
		debugPrint = false
		super.setUp()
	}
//
//	func test_transactionManifest_toString_on_multiple_packages() throws {
//		let packages = [
//			try (
//				code: resource(named: "hello", extension: "code"),
//				schema: resource(named: "hello", extension: "schema")
//			),
//			try (
//				code: resource(named: "hello_world", extension: "code"),
//				schema: resource(named: "hello_world", extension: "schema")
//			),
//			try (
//				code: resource(named: "RaDEX", extension: "code"),
//				schema: resource(named: "RaDEX", extension: "schema")
//			),
//			try (
//				code: resource(named: "account", extension: "code"),
//				schema: resource(named: "account", extension: "schema")
//			),
//			try (
//				code: resource(named: "faucet", extension: "code"),
//				schema: resource(named: "faucet", extension: "schema")
//			),
//		]
//
//		let accessRules = Tuple {
//			Map_(keyKind: .tuple, valueKind: .enum, entries: [])
//			Map_(keyKind: .string, valueKind: .enum, entries: [])
//			Enum(.u8(0), fields: [])
//			Map_(keyKind: .tuple, valueKind: .enum, entries: [])
//			Map_(keyKind: .string, valueKind: .enum, entries: [])
//			Enum(.u8(0), fields: [])
//		}
//
//		for package in packages {
//			let manifestInstructions = try TransactionManifest {
//				try CallMethod(
//					receiver: .init(validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q"),
//					methodName: "lock_fee"
//				) { Decimal_(value: "100") }
//
//				try PublishPackage(
//					code: Blob(data: blake2b(data: package.code)),
//					schema: Bytes(bytes: blake2b(data: package.schema).bytes),
//					royaltyConfig: Map_(keyKind: .string, valueKind: .tuple, entries: []),
//					metadata: Map_(keyKind: .string, valueKind: .string, entries: [])
//				)
//			}.instructions
//
//			let transactionManifest = TransactionManifest(
//				instructions: manifestInstructions,
//				blobs: [
//					[UInt8](package.code),
//					[UInt8](package.schema),
//				]
//			)
//
//			for outputInstructionKind in [ManifestInstructionsKind.parsed, ManifestInstructionsKind.string] {
//				XCTAssertNoThrow(try sut.convertManifest(request: ConvertManifestRequest(
//					manifest: transactionManifest,
//					outputFormat: outputInstructionKind,
//					networkId: .simulator
//				)).get().toString(networkID: .simulator))
//			}
//		}
//	}
}

public func resource(
	named fileName: String,
	extension fileExtension: String
) throws -> Data {
	let fileURL = Bundle.module.url(forResource: fileName, withExtension: fileExtension)
	return try Data(contentsOf: fileURL!)
}
