@testable import EngineToolkit

final class DecompileTransactionIntentTests: TestCase {
	func test__decompile_transaction_intent_does_not_throw_ed25519() throws {
		let testTransaction = try testTransactionEd25519(signerCount: 5)
		let request = DecompileTransactionIntentRequest(
			compiledIntent: testTransaction.compiledTransactionIntent,
			manifestInstructionsOutputFormat: .string
		)
		XCTAssertNoThrow(try sut.decompileTransactionIntentRequest(request: request).get())
	}

	func test__decompile_transaction_intent_does_not_throw_secp256k1() throws {
		let testTransaction = try testTransactionSecp256k1(signerCount: 5)
		let request = DecompileTransactionIntentRequest(
			compiledIntent: testTransaction.compiledTransactionIntent,
			manifestInstructionsOutputFormat: .string
		)
		XCTAssertNoThrow(try sut.decompileTransactionIntentRequest(request: request).get())
	}
}
