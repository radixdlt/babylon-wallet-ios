@testable import EngineToolkit

final class CompileSignedTransactionIntentTests: TestCase {
	func test__compile_signed_transaction_intent_does_not_throw_ed25519() throws {
		let request = try testTransactionEd25519(signerCount: 0).notarizedTransaction.signedIntent
		XCTAssertNoThrow(try sut.compileSignedTransactionIntentRequest(request: request).get())
	}

	func test__compile_signed_transaction_intent_does_not_throw_secp256k1() throws {
		let request = try testTransactionSecp256k1(signerCount: 0).notarizedTransaction.signedIntent
		XCTAssertNoThrow(try sut.compileSignedTransactionIntentRequest(request: request).get())
	}
}
