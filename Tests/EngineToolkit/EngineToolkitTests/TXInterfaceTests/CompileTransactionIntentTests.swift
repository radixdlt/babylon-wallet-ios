@testable import EngineToolkit
import TestingPrelude

final class CompileTransactionIntentTests: TestCase {
	override func setUp() {
		debugPrint = true
		super.setUp()
	}

	func test__compile_transaction_intent_does_not_throw_ed25519() throws {
		let request = try testTransactionEd25519(signerCount: 0).notarizedTransaction.signedIntent.intent
		XCTAssertNoThrow(try sut.compileTransactionIntentRequest(request: request).get())
	}

	func test__compile_transaction_intent_does_not_throw_secp256k1() throws {
		let request = try testTransactionSecp256k1(signerCount: 0).notarizedTransaction.signedIntent.intent
		XCTAssertNoThrow(try sut.compileTransactionIntentRequest(request: request).get())
	}
}
