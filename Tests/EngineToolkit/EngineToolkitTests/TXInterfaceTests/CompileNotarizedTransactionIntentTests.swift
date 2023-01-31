import Cryptography
@testable import EngineToolkit
import TestingPrelude

final class CompileNotarizedTransactionIntentTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
	}

	func test__compile_notarized_transaction_does_not_throw_ed25519() throws {
		let request = try testTransactionEd25519(signerCount: 0).notarizedTransaction
		XCTAssertNoThrow(try sut.compileNotarizedTransactionIntentRequest(request: request).get())
	}

	func test__compile_notarized_transaction_does_not_throw_secp256k1() throws {
		let request = try testTransactionSecp256k1(signerCount: 0).notarizedTransaction
		XCTAssertNoThrow(try sut.compileNotarizedTransactionIntentRequest(request: request).get())
	}

	func test__common_manifests_can_be_notarized_without_issues() throws {
		let testVectors: [(manifest: String, blobs: [[UInt8]])] = [
			(
				manifest: String(decoding: try resource(named: "multi_account_resource_transfer", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "resource_transfer", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "free_funds", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "publish_with_owner", extension: ".rtm"), as: UTF8.self),
				blobs: [
					[10],
					[10],
				]
			),
			(
				manifest: String(decoding: try resource(named: "no_initial_supply_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "with_initial_supply_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "no_initial_supply_non_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "with_initial_supply_non_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "mint_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
			(
				manifest: String(decoding: try resource(named: "mint_non_fungible", extension: ".rtm"), as: UTF8.self),
				blobs: []
			),
		]

		for testVector in testVectors {
			let manifestString = testVector
				.manifest
				.replacingOccurrences(of: "{xrd_resource_address}", with: "resource_sim1qzkcyv5dwq3r6kawy6pxpvcythx8rh8ntum6ws62p95sqjjpwr")
				.replacingOccurrences(of: "{faucet_component_address}", with: "component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
				.replacingOccurrences(of: "{this_account_component_address}", with: "account_sim1qwskd4q5jdywfw6f7jlwmcyp2xxq48uuwruc003x2kcskxh3na")
				.replacingOccurrences(of: "{account_component_address}", with: "account_sim1qwskd4q5jdywfw6f7jlwmcyp2xxq48uuwruc003x2kcskxh3na")
				.replacingOccurrences(of: "{other_account_component_address}", with: "account_sim1qdy4jqfpehf8nv4n7680cw0vhxqvhgh5lf3ae8jkjz6q5hmzed")
				.replacingOccurrences(of: "{account_a_component_address}", with: "account_sim1qwssydet6r0wen92wzs3nex8x9ch5ye0uz9tzgq5nchq86xmpm")
				.replacingOccurrences(of: "{account_b_component_address}", with: "account_sim1qdxpdrpjtsqmumccye045u4cfw2fqa3a9gujh6qvdresgnl2nh")
				.replacingOccurrences(of: "{account_c_component_address}", with: "account_sim1qd4jtjgqxtmk2m7ze0cpa6ugae8jwfhgxqenvw6m6uwqgqmp4q")
				.replacingOccurrences(of: "{owner_badge_resource_address}", with: "resource_sim1qrtkj5zx7tcpuhwjxerhhnmwv58k9v5yyjqgqt7rtnxsnqyl3s")
				.replacingOccurrences(of: "{minter_badge_resource_address}", with: "resource_sim1qp075qmn6389pkq30ppzzsuadd55ry04mjx69v86r4wq0feh02")
				.replacingOccurrences(of: "{mintable_resource_address}", with: "resource_sim1qqgvpz8q7ypeueqcv4qthsv7ezt8h9m3depmqqw7pc4sfmucfx")
				.replacingOccurrences(of: "{owner_badge_non_fungible_local_id}", with: "12")
				.replacingOccurrences(of: "{code_blob_hash}", with: sha256(data: Data([10])).hex)
				.replacingOccurrences(of: "{abi_blob_hash}", with: sha256(data: Data([10])).hex)
				.replacingOccurrences(of: "{initial_supply}", with: "12")
				.replacingOccurrences(of: "{mint_amount}", with: "12")
				.replacingOccurrences(of: "{non_fungible_local_id}", with: "12u32")

			let notaryPrivateKey = Engine.PrivateKey.secp256k1(try K1.PrivateKey.generateNew())
			let notarizedTransaction = try TransactionManifest(instructions: .string(manifestString), blobs: testVector.blobs.map { [UInt8]($0) })
				.header(TransactionHeader(
					version: 0x01,
					networkId: 0xF2,
					startEpochInclusive: 0,
					endEpochExclusive: 10,
					nonce: 0,
					publicKey: try notaryPrivateKey.publicKey(),
					notaryAsSignatory: true,
					costUnitLimit: 10_000_000,
					tipPercentage: 0
				))
				.notarize(notaryPrivateKey)

			XCTAssertNoThrow(try sut.compileNotarizedTransactionIntentRequest(request: notarizedTransaction.notarizedTransaction).get())
		}
	}
}
