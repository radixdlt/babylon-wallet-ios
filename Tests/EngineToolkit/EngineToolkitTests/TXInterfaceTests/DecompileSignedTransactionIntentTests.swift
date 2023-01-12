@testable import EngineToolkit
import TestingPrelude

final class DecompileSignedTransactionIntentTests: TestCase {
	func test__decompile_signed_transaction_intent_does_not_throw_ed25519() throws {
		let testTransaction = try testTransactionEd25519(signerCount: 5)
		let request = DecompileSignedTransactionIntentRequest(
			compiledSignedIntent: testTransaction.compiledSignedTransactionIntent,
			manifestInstructionsOutputFormat: .string
		)
		XCTAssertNoThrow(try sut.decompileSignedTransactionIntentRequest(request: request).get())
	}

	func test__decompile_signed_transaction_intent_does_not_throw_secp256k1() throws {
		let testTransaction = try testTransactionSecp256k1(signerCount: 5)
		let request = DecompileSignedTransactionIntentRequest(
			compiledSignedIntent: testTransaction.compiledSignedTransactionIntent,
			manifestInstructionsOutputFormat: .string
		)
		XCTAssertNoThrow(try sut.decompileSignedTransactionIntentRequest(request: request).get())
	}
}
