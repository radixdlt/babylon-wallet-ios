@testable import EngineToolkit
import TestingPrelude

final class DecompileNotarizedTransactionIntentTests: TestCase {
	func test__decompile_notarized_transaction_does_not_throw_ed25519() throws {
		let testTransaction = try testTransactionEd25519(signerCount: 5)
		let request = DecompileNotarizedTransactionIntentRequest(
			compiledNotarizedIntent: testTransaction.compiledNotarizedTransactionIntent,
			instructionsOutputKind: .string
		)
		XCTAssertNoThrow(try sut.decompileNotarizedTransactionIntentRequest(request: request).get())
	}

	func test__decompile_notarized_transaction_does_not_throw_secp256k1() throws {
		let testTransaction = try testTransactionSecp256k1(signerCount: 5)
		let request = DecompileNotarizedTransactionIntentRequest(
			compiledNotarizedIntent: testTransaction.compiledNotarizedTransactionIntent,
			instructionsOutputKind: .string
		)
		XCTAssertNoThrow(try sut.decompileNotarizedTransactionIntentRequest(request: request).get())
	}
}
