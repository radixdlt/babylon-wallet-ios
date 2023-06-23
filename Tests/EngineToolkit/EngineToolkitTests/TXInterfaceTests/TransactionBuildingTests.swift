import Cryptography
@testable import EngineToolkit
import TestingPrelude

// MARK: - TransactionBuildingTests
final class TransactionBuildingTests: TestCase {
	func test_building_notarized_transaction() throws {
		let privateKeyA = Engine.PrivateKey.curve25519(.init())
		let privateKeyB = Engine.PrivateKey.curve25519(.init())
		let privateKeyC = Engine.PrivateKey.curve25519(.init())
		let notaryPrivateKey = Engine.PrivateKey.secp256k1(.init())

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

		let signedIntentHash = try RadixEngine.instance
			.hashSignedTransactionIntent(signedTransactionIntent)
			.get().hash

		let isValid = try notaryPrivateKey
			.publicKey()
			.isValidSignature(
				txContext.notarizedTransaction.notarySignature,
				hashed: signedIntentHash
			)

		XCTAssertTrue(isValid)
	}
}

extension TransactionHeader {
	public static func example(
		notaryPrivateKey: Engine.PrivateKey
	) throws -> Self {
		try Self(
			networkId: 0xF2,
			startEpochInclusive: 0,
			endEpochExclusive: 10,
			nonce: 0,
			publicKey: notaryPrivateKey.publicKey(),
			notaryIsSignatory: true,
			tipPercentage: 0
		)
	}
}
