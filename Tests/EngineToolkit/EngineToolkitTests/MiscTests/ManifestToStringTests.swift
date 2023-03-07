import Cryptography
@testable import EngineToolkit
import TestingPrelude

// MARK: - ManifestToStringTests
final class ManifestToStringTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test_transactionManifest_toString_on_multiple_packages() throws {
		let packages = [
			(
				code: try resource(named: "hello", extension: "code"),
				schema: try resource(named: "hello", extension: "schema")
			),
			(
				code: try resource(named: "hello_world", extension: "code"),
				schema: try resource(named: "hello_world", extension: "schema")
			),
			(
				code: try resource(named: "RaDEX", extension: "code"),
				schema: try resource(named: "RaDEX", extension: "schema")
			),
			(
				code: try resource(named: "account", extension: "code"),
				schema: try resource(named: "account", extension: "schema")
			),
			(
				code: try resource(named: "faucet", extension: "code"),
				schema: try resource(named: "faucet", extension: "schema")
			),
		]

		for package in packages {
			let manifestInstructions = TransactionManifest {
				CallMethod(
					receiver: ComponentAddress("account_sim1qdfapg25xjpned3q5k8vcku6vdp55rs493lqtjeky9wqse9w34"),
					methodName: "lock_fee"
				) { Decimal_(value: "100") }

				PublishPackageWithOwner(
					code: Blob(data: sha256(data: package.code)),
					abi: Blob(data: sha256(data: package.abi)),
					ownerBadge: NonFungibleGlobalId(
						resourceAddress: .init(address: "resource_sim1qzf8hl3azz2q0e5s33nh2mt8wmvqjfxdrv06ysus4alqh0994h"),
						nonFungibleLocalId: .integer(12)
					)
				)
			}.instructions

			let transactionManifest = TransactionManifest(
				instructions: manifestInstructions,
				blobs: [
					[UInt8](package.code),
					[UInt8](package.schema),
				]
			)

			for outputInstructionKind in [ManifestInstructionsKind.parsed, ManifestInstructionsKind.string] {
				XCTAssertNoThrow(try sut.convertManifest(request: ConvertManifestRequest(
					manifest: transactionManifest,
					outputFormat: outputInstructionKind,
					networkId: 0xF2
				)).get().toString(networkID: 0xF2))
			}
		}
	}
}

public func resource(
	named fileName: String,
	extension fileExtension: String
) throws -> Data {
	let fileURL = Bundle.module.url(forResource: fileName, withExtension: fileExtension)
	return try Data(contentsOf: fileURL!)
}

public func sha256(data: Data) -> Data {
	SHA256.hash(data: data).data
}
