import CryptoKit
@testable import EngineToolkit

// MARK: - TransactionBuildingTests
final class TransactionBuildingTests: TestCase {
	func test_building_notarized_transaction() throws {
		let privateKeyA = Engine.PrivateKey.curve25519(.init())
		let privateKeyB = Engine.PrivateKey.curve25519(.init())
		let privateKeyC = Engine.PrivateKey.curve25519(.init())
		let notaryPrivateKey = Engine.PrivateKey.curve25519(.init())

		let txContext = try TransactionManifest.complex
			.header(.example(notaryPrivateKey: notaryPrivateKey))
			.blobs([[0xDE, 0xAD], [0xBE, 0xEF]])
			.sign(with: privateKeyA)
			.sign(with: privateKeyB)
			.sign(with: privateKeyC)
			.notarize(notaryPrivateKey)

		let signedTransactionIntent = SignedTransactionIntent(
			intent: txContext.notarizedTransaction.signedIntent.intent,
			intentSignatures: txContext.notarizedTransaction.signedIntent.intentSignatures
		)

		let compiledSignedTransactionIntent = try EngineToolkit().compileSignedTransactionIntentRequest(
			request: signedTransactionIntent
		).get().compiledSignedIntent

		let isValid = try notaryPrivateKey
			.publicKey()
			.isValidSignature(
				txContext.notarizedTransaction.notarySignature,
				for: compiledSignedTransactionIntent
			)

		XCTAssertTrue(isValid)
	}
}

public extension TransactionHeader {
	static func example(
		notaryPrivateKey: Engine.PrivateKey
	) throws -> Self {
		try Self(
			version: 0x01,
			networkId: 0xF2,
			startEpochInclusive: 0,
			endEpochExclusive: 10,
			nonce: 0,
			publicKey: notaryPrivateKey.publicKey(),
			notaryAsSignatory: true,
			costUnitLimit: 10_000_000,
			tipPercentage: 0
		)
	}
}
