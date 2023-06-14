import Cryptography
@testable import EngineToolkit

extension TransactionManifest {
	static let complex = Self(instructions: .string(complexManifestString))
}

private let complexManifestString = """
DROP_ALL_PROOFS;
"""

typealias TestTransaction = (
	notarizedTransaction: NotarizedTransaction,
	compiledTransactionIntent: [UInt8],
	compiledSignedTransactionIntent: [UInt8],
	compiledNotarizedTransactionIntent: [UInt8]
)

// All cryptographic signatures required for this test transaction are done through
// the EdDSA Ed25519 curve.
func testTransactionEd25519(
	signerCount: UInt,
	notaryAsSignatory: Bool = true,
	file: StaticString = #file,
	line: UInt = #line
) throws -> TestTransaction {
	// Creating the private keys of the notary and the other signers
	try _testTransaction(
		notaryPrivateKey: .curve25519(.init()),
		signerPrivateKeys: (0 ..< signerCount).map { _ in .curve25519(.init()) },
		file: file, line: line
	)
}

// All cryptographic signatures required for this test transaction are done through
// the ECDAS `secp256k1` curve.
func testTransactionSecp256k1(
	signerCount: UInt,
	notaryAsSignatory: Bool = true,
	file: StaticString = #file,
	line: UInt = #line
) throws -> TestTransaction {
	try _testTransaction(
		notaryPrivateKey: .secp256k1(K1.PrivateKey()),
		signerPrivateKeys: (0 ..< signerCount).map { _ in .secp256k1(K1.PrivateKey()) },
		file: file, line: line
	)
}

private func _testTransaction(
	notaryPrivateKey: Engine.PrivateKey,
	signerPrivateKeys: [Engine.PrivateKey],
	notaryAsSignatory: Bool = true,
	file: StaticString = #file,
	line: UInt = #line
) throws -> TestTransaction {
	// The engine toolkit to use to create this notarized transaction
	let sut = RadixEngine.instance

	let transactionManifest = TransactionManifest(instructions: .string(complexManifestString))
	let transactionHeader = try TransactionHeader(
		networkId: 0xF2,
		startEpochInclusive: 0,
		endEpochExclusive: 10,
		nonce: 0,
		publicKey: notaryPrivateKey.publicKey(),
		notaryIsSignatory: notaryAsSignatory,
		tipPercentage: 0
	)

	let signedTXContext = try transactionManifest
		.header(transactionHeader)
		.sign(withMany: signerPrivateKeys)
		.notarize(notaryPrivateKey)

	let compiledNotarizedTransactionIntent = try sut.compileNotarizedTransactionIntentRequest(request: signedTXContext.notarizedTransaction).get().compiledIntent

	return (
		notarizedTransaction: signedTXContext.notarizedTransaction,
		compiledTransactionIntent: signedTXContext.compileTransactionIntentResponse.compiledIntent,
		compiledSignedTransactionIntent: signedTXContext.compileSignedTransactionIntentResponse.compiledIntent,
		compiledNotarizedTransactionIntent: compiledNotarizedTransactionIntent
	)
}
