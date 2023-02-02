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
		for testVector in try manifestTestVectors() {
			let notaryPrivateKey = Engine.PrivateKey.secp256k1(try K1.PrivateKey.generateNew())
			let notarizedTransaction = try TransactionManifest(instructions: .string(testVector.manifest), blobs: testVector.blobs.map { [UInt8]($0) })
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
