import Cryptography
@testable import EngineToolkit

extension TransactionManifest {
	static let complex = Self(instructions: .string(complexManifestString))
}

private let complexManifestString = """
# Withdraw XRD from account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "withdraw_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");

# Buy GUM with XRD
TAKE_FROM_WORKTOP_BY_AMOUNT Decimal("2.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("xrd");
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "buy_gumball" Bucket("xrd");
ASSERT_WORKTOP_CONTAINS_BY_AMOUNT Decimal("3.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
ASSERT_WORKTOP_CONTAINS ResourceAddress("resource_sim1qzhdk7tq68u8msj38r6v6yqa5myc64ejx3ud20zlh9gseqtux6");

# Create a proof from bucket, clone it and drop both
TAKE_FROM_WORKTOP ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("some_xrd");
CREATE_PROOF_FROM_BUCKET Bucket("some_xrd") Proof("proof1");
CLONE_PROOF Proof("proof1") Proof("proof2");
DROP_PROOF Proof("proof1");
DROP_PROOF Proof("proof2");

# Create a proof from account and drop it
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "create_proof_by_amount" Decimal("5.0") ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag");
POP_FROM_AUTH_ZONE Proof("proof3");
DROP_PROOF Proof("proof3");

# Return a bucket to worktop
RETURN_TO_WORKTOP Bucket("some_xrd");
TAKE_FROM_WORKTOP_BY_IDS Array<NonFungibleLocalId>(NonFungibleLocalId(Bytes("031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f"))) ResourceAddress("resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag") Bucket("nfts");

# Create a new fungible resource
CREATE_RESOURCE Enum("Fungible", 0u8) Array<Tuple>() Array<Tuple>() Enum("Some", Enum("Fungible", Decimal("1.0")));

# Cancel all buckets and move resources to account
CALL_METHOD ComponentAddress("account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064") "deposit_batch" Expression("ENTIRE_WORKTOP");

# Drop all proofs
DROP_ALL_PROOFS;

# Complicated method that takes all of the number types
CALL_METHOD ComponentAddress("component_sim1q2f9vmyrmeladvz0ejfttcztqv3genlsgpu9vue83mcs835hum") "complicated_method" Decimal("1") PreciseDecimal("2");
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
		notaryPrivateKey: .secp256k1(try K1.PrivateKey.generateNew()),
		signerPrivateKeys: (0 ..< signerCount).map { _ in .secp256k1(try K1.PrivateKey.generateNew()) },
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
	let sut = EngineToolkit()

	let transactionManifest = TransactionManifest(instructions: .string(complexManifestString))
	let transactionHeader = TransactionHeader(
		version: 0x01,
		networkId: 0xF2,
		startEpochInclusive: 0,
		endEpochExclusive: 10,
		nonce: 0,
		publicKey: try notaryPrivateKey.publicKey(),
		notaryAsSignatory: notaryAsSignatory,
		costUnitLimit: 10_000_000,
		tipPercentage: 0
	)

	let signedTXContext = try transactionManifest
		.header(transactionHeader)
		.sign(withMany: signerPrivateKeys)
		.notarize(notaryPrivateKey)

	let compiledNotarizedTransactionIntent = try sut.compileNotarizedTransactionIntentRequest(request: signedTXContext.notarizedTransaction).get().compiledNotarizedIntent

	return (
		notarizedTransaction: signedTXContext.notarizedTransaction,
		compiledTransactionIntent: signedTXContext.compileTransactionIntentResponse.compiledIntent,
		compiledSignedTransactionIntent: signedTXContext.compileSignedTransactionIntentResponse.compiledSignedIntent,
		compiledNotarizedTransactionIntent: compiledNotarizedTransactionIntent
	)
}
